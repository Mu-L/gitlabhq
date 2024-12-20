# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        class Database < Target
          attr_reader :errors

          IGNORED_ERRORS = [
            # Ignore warnings
            /WARNING:/,
            # Ignore the DROP errors; recent database dumps will use --if-exists with pg_dump
            /does not exist$/,
            # User may not have permissions to drop extensions or schemas
            /must be owner of/
          ].freeze
          IGNORED_ERRORS_REGEXP = Regexp.union(IGNORED_ERRORS).freeze

          def initialize
            @errors = []
          end

          def dump(destination_dir)
            FileUtils.mkdir_p(destination_dir)

            each_database(destination_dir) do |backup_connection|
              pg_env = backup_connection.database_configuration.pg_env_variables
              active_record_config = backup_connection.database_configuration.activerecord_variables
              pg_database_name = active_record_config[:database]

              dump_file_name = file_name(destination_dir, backup_connection.connection_name)
              FileUtils.rm_f(dump_file_name)

              Gitlab::Backup::Cli::Output.print_info("Dumping PostgreSQL database #{pg_database_name} ... ")

              schemas = []

              if Gitlab.config.backup.pg_schema
                schemas << Gitlab.config.backup.pg_schema
                schemas.push(*Gitlab::Database::EXTRA_SCHEMAS.map(&:to_s))
              end

              pg_dump = ::Gitlab::Backup::Cli::Utils::PgDump.new(
                database_name: pg_database_name,
                snapshot_id: backup_connection.snapshot_id,
                schemas: schemas,
                env: pg_env)

              success = ::Backup::Dump::Postgres.new.dump(dump_file_name, pg_dump)

              backup_connection.release_snapshot! if backup_connection.snapshot_id

              raise DatabaseBackupError.new(active_record_config, dump_file_name) unless success

              report_finish_status(success)
            end
          ensure
            if multiple_databases?
              ::Gitlab::Database::EachDatabase.each_connection(
                only: base_models_for_backup.keys, include_shared: false
              ) do |_, database_connection_name|
                backup_connection = ::Backup::DatabaseConnection.new(database_connection_name)
                backup_connection.restore_timeouts!
              rescue ActiveRecord::ConnectionNotEstablished
                raise DatabaseBackupError.new(
                  backup_connection.database_configuration.activerecord_variables,
                  file_name(destination_dir, database_connection_name)
                )
              end
            end
          end

          def restore(destination_dir)
            base_models_for_backup.each do |database_name, _|
              backup_connection = ::Backup::DatabaseConnection.new(database_name)

              config = backup_connection.database_configuration.activerecord_variables

              db_file_name = file_name(destination_dir, database_name)
              database = config[:database]

              unless File.exist?(db_file_name)
                if main_database?(database_name)
                  raise(DatabaseBackupError, "Source database file does not exist #{db_file_name}")
                end

                Gitlab::Backup::Cli::Output.warning(
                  "Source backup for the database #{database_name} doesn't exist. Skipping the task"
                )

                return false
              end

              Gitlab::Backup::Cli::Output.warning("Removing all tables from #{database_name}.")

              # Drop all tables Load the schema to ensure we don't have any newer tables
              # hanging out from a failed upgrade
              drop_tables(database_name)

              pg_env = backup_connection.database_configuration.pg_env_variables

              pipeline = Gitlab::Backup::Cli::Shell::Pipeline.new(
                Utils::Compression.decompression_command,
                pg_restore_cmd(database, pg_env)
              )

              Gitlab::Backup::Cli::Output.print_info "Restoring PostgreSQL database #{database} ... "

              pipeline_status = pipeline.run!(input: db_file_name)
              tracked_errors = pipeline_status.stderr

              unless tracked_errors.empty?
                Gitlab::Backup::Cli::Output.error "------ BEGIN ERRORS -----"
                Gitlab::Backup::Cli::Output.print(tracked_errors.join, stderr: true)
                Gitlab::Backup::Cli::Output.error "------ END ERRORS -------"
              end

              report_finish_status(pipeline_status.success?)

              raise DatabaseBackupError, 'Restore failed' unless pipeline_status.success?
            end
          end

          protected

          def base_models_for_backup
            @base_models_for_backup ||= ::Gitlab::Database.database_base_models_with_gitlab_shared
          end

          def main_database?(database_name)
            database_name.to_sym == :main
          end

          def file_name(base_dir, database_name)
            prefix = database_name.to_sym != :main ? "#{database_name}_" : ''

            File.join(base_dir, "#{prefix}database.sql.gz")
          end

          def ignore_error?(line)
            IGNORED_ERRORS_REGEXP.match?(line)
          end

          private

          def report_finish_status(status)
            Gitlab::Backup::Cli::Output.print_tag(status ? :success : :failure)
          end

          def drop_tables(database_name)
            Gitlab::Backup::Cli::Output.info 'Cleaning the database ... '

            if Rake::Task.task_defined? "gitlab:db:drop_tables:#{database_name}"
              Rake::Task["gitlab:db:drop_tables:#{database_name}"].invoke
            else
              # In single database (single or two connections)
              Rake::Task["gitlab:db:drop_tables"].invoke
            end

            Gitlab::Backup::Cli::Output.print_tag(:success)
          end

          # @deprecated This will be removed when restore operation is refactored to use extended_env directly
          def with_transient_pg_env(extended_env)
            ENV.merge!(extended_env)
            result = yield
            ENV.reject! { |k, _| extended_env.key?(k) }

            result
          end

          def pg_restore_cmd(database, pg_env)
            Shell::Command.new('psql', database, env: pg_env)
          end

          def each_database(destination_dir, &block)
            databases = []

            # each connection will loop through all database connections defined in `database.yml`
            # and reject the ones that are shared, so we don't get duplicates
            #
            # we consider a connection to be shared when it has `database_tasks: false`
            ::Gitlab::Database::EachDatabase.each_connection(
              only: base_models_for_backup.keys, include_shared: false
            ) do |_, database_connection_name|
              backup_connection = ::Backup::DatabaseConnection.new(database_connection_name)
              databases << backup_connection

              next unless multiple_databases?

              begin
                # Trigger a transaction snapshot export that will be used by pg_dump later on
                backup_connection.export_snapshot!
              rescue ActiveRecord::ConnectionNotEstablished
                raise DatabaseBackupError.new(
                  backup_connection.database_configuration.activerecord_variables,
                  file_name(destination_dir, database_connection_name)
                )
              end
            end

            databases.each(&block)
          end

          def multiple_databases?
            ::Gitlab::Database.database_mode == ::Gitlab::Database::MODE_MULTIPLE_DATABASES
          end
        end
      end
    end
  end
end

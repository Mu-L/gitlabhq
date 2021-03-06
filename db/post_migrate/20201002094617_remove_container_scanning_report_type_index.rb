# frozen_string_literal: true

class RemoveContainerScanningReportTypeIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_container_scanning_findings'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:vulnerability_occurrences, INDEX_NAME)
  end

  def down
    # report_type: 2 container scanning
    add_concurrent_index(
      :vulnerability_occurrences,
      :id,
      where: 'report_type = 2',
      name: INDEX_NAME
    )
  end
end

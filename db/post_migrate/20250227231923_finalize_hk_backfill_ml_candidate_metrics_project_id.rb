# frozen_string_literal: true

class FinalizeHkBackfillMlCandidateMetricsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMlCandidateMetricsProjectId',
      table_name: :ml_candidate_metrics,
      column_name: :id,
      job_arguments: [:project_id, :ml_candidates, :project_id, :candidate_id],
      finalize: true
    )
  end

  def down; end
end

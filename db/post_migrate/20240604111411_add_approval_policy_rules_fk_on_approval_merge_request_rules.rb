# frozen_string_literal: true

class AddApprovalPolicyRulesFkOnApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_merge_request_rules_on_approval_policy_rule_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- large tables
    add_concurrent_index :approval_merge_request_rules, :approval_policy_rule_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
    add_concurrent_foreign_key :approval_merge_request_rules, :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :approval_merge_request_rules, column: :approval_policy_rule_id
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end

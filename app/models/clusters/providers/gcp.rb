# frozen_string_literal: true

module Clusters
  module Providers
    class Gcp < ApplicationRecord
      include Clusters::Concerns::ProviderStatus
      include Gitlab::EncryptedAttribute

      self.table_name = 'cluster_providers_gcp'

      belongs_to :cluster, inverse_of: :provider_gcp, class_name: 'Clusters::Cluster'

      attribute :zone, default: 'us-central1-a'
      attribute :num_nodes, default: 3
      attribute :machine_type, default: 'n1-standard-2'
      attribute :cloud_run, default: false

      scope :cloud_run, -> { where(cloud_run: true) }

      attr_encrypted :access_token,
        mode: :per_attribute_iv,
        key: :db_key_base_truncated,
        algorithm: 'aes-256-cbc'

      validates :gcp_project_id,
        length: 1..63,
        format: {
          with: Gitlab::Regex.kubernetes_namespace_regex,
          message: Gitlab::Regex.kubernetes_namespace_regex_message
        }

      validates :zone, presence: true

      validates :num_nodes,
        presence: true,
        numericality: {
          only_integer: true,
          greater_than: 0
        }

      def nullify_credentials
        assign_attributes(
          access_token: nil,
          operation_id: nil
        )
      end

      def assign_operation_id(operation_id)
        assign_attributes(operation_id: operation_id)
      end

      def has_rbac_enabled?
        !legacy_abac
      end

      def knative_pre_installed?
        cloud_run?
      end
    end
  end
end

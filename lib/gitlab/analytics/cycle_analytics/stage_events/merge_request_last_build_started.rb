# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestLastBuildStarted < MetricsBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request last build started")
          end

          def self.identifier
            :merge_request_last_build_started
          end

          def object_type
            MergeRequest
          end

          def column_list
            [mr_metrics_table[:latest_build_started_at]]
          end
        end
      end
    end
  end
end

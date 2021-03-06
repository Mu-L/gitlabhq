# frozen_string_literal: true

module Types
  class MergeRequestStateEnum < IssuableStateEnum
    graphql_name 'MergeRequestState'
    description 'State of a GitLab merge request'

    value 'merged', description: "Merge request has been merged."
  end
end

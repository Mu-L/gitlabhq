# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerArchitectureType < BaseObject
      graphql_name 'RunnerArchitecture'

      field :download_location,
        GraphQL::Types::String,
        null: false,
        description: 'Download location for the runner for the platform architecture.'
      field :name, GraphQL::Types::String, null: false,
        description: 'Name of the runner platform architecture.'
    end
  end
end

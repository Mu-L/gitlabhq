# frozen_string_literal: true

FactoryBot.define do
  factory :pool_repository do
    shard { Shard.by_name("default") }
    state { :none }

    transient do
      with_project { true }
    end

    before(:create) do |pool, context|
      if context.with_project
        pool.source_project ||= create(:project, :repository)
        pool.source_project.update!(pool_repository: pool)
      end
    end

    trait :scheduled do
      state { :scheduled }
    end

    trait :failed do
      state { :failed }
    end

    trait :obsolete do
      state { :obsolete }
    end

    trait :ready do
      state { :ready }

      after(:create) do |pool|
        pool.create_object_pool
      end
    end

    trait :without_project do
      transient do
        with_project { false }
      end
    end
  end
end

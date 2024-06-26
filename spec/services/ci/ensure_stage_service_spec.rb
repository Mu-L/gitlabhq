# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::EnsureStageService, '#execute', feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:stage) { create(:ci_stage) }
  let(:job) { build(:ci_build) }

  let(:service) { described_class.new(project, user) }

  before do
    stub_feature_flags(ci_remove_ensure_stage_service: false)
  end

  context 'when build has a stage assigned' do
    it 'does not create a new stage' do
      job.assign_attributes(stage_id: stage.id)

      expect { service.execute(job) }.not_to change { Ci::Stage.count }
    end
  end

  context 'when build does not have a stage assigned' do
    it 'creates a new stage' do
      job.assign_attributes(stage_id: nil, stage: 'test')

      expect { service.execute(job) }.to change { Ci::Stage.count }.by(1)
    end
  end

  context 'when build is invalid' do
    it 'does not create a new stage' do
      job.assign_attributes(stage_id: nil, ref: nil)

      expect { service.execute(job) }.not_to change { Ci::Stage.count }
    end
  end

  context 'when new stage can not be created because of an exception' do
    before do
      allow(Ci::Stage).to receive(:create!)
        .and_raise(ActiveRecord::RecordNotUnique.new('Duplicates!'))
    end

    it 'retries up to two times' do
      job.assign_attributes(stage_id: nil)

      expect(service).to receive(:find_stage).twice

      expect { service.execute(job) }
        .to raise_error(Ci::EnsureStageService::EnsureStageError)
    end
  end
end

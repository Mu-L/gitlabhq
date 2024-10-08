# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/Test.gitlab-ci.yml', feature_category: :continuous_integration do
  include Ci::PipelineMessageHelpers

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Jobs/Test') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'on master' do
      it 'creates the test job' do
        expect(build_names).to contain_exactly('test')
      end
    end

    context 'on another branch' do
      let(:pipeline_ref) { 'feature' }

      it 'creates the test job' do
        expect(build_names).to contain_exactly('test')
      end
    end

    context 'on tag' do
      let(:pipeline_ref) { 'v1.0.0' }

      it 'creates the test job' do
        expect(pipeline).to be_tag
        expect(build_names).to contain_exactly('test')
      end
    end

    context 'on merge request' do
      let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project) }
      let(:pipeline) { service.execute(merge_request).payload }

      it 'has no jobs' do
        expect(pipeline).to be_merge_request_event
        expect(build_names).to be_empty
      end
    end

    context 'TEST_DISABLED is set' do
      before do
        create(:ci_variable, key: 'TEST_DISABLED', value: 'true', project: project)
      end

      context 'on master' do
        it 'has no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array([sanitize_message(Ci::Pipeline.rules_failure_message)])
        end
      end

      context 'on another branch' do
        let(:pipeline_ref) { 'feature' }

        it 'has no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array([sanitize_message(Ci::Pipeline.rules_failure_message)])
        end
      end

      context 'on tag' do
        let(:pipeline_ref) { 'v1.0.0' }

        it 'has no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array([sanitize_message(Ci::Pipeline.rules_failure_message)])
        end
      end
    end
  end
end

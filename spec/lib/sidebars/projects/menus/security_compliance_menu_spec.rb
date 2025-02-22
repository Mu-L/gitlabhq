# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::SecurityComplianceMenu do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:show_promotions) { true }
  let(:show_discover_project_security) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_promotions: show_promotions, show_discover_project_security: show_discover_project_security) }

  describe 'render?' do
    subject { described_class.new(context).render? }

    context 'when user is not authenticated' do
      let(:user) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when user is authenticated' do
      context 'when the Security and compliance is disabled' do
        let_it_be(:project) { create(:project, :security_and_compliance_disabled) }

        before do
          allow(project).to receive(:security_and_compliance_enabled?).and_return(false)
        end

        it { is_expected.to be_falsey }
      end

      context 'when the Security and compliance is not disabled' do
        it { is_expected.to be_truthy }
      end
    end
  end
end

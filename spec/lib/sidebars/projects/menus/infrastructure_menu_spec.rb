# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::InfrastructureMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: false) }

  it_behaves_like 'not serializable as super_sidebar_menu_args' do
    let(:menu) { described_class.new(context) }
  end

  describe '#render?' do
    subject { described_class.new(context) }

    context 'when menu does not have any menu items' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to be false
      end
    end

    context 'when menu has menu items' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end

    describe 'behavior based on access level setting' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:project) { create(:project) }
      let(:enabled) { Featurable::PRIVATE }
      let(:disabled) { Featurable::DISABLED }

      where(:infrastructure_access_level, :render) do
        ref(:enabled)  | true
        ref(:disabled) | false
      end

      with_them do
        it 'renders based on the infrastructure access level' do
          project.project_feature.update!(infrastructure_access_level: infrastructure_access_level)

          expect(subject.render?).to be render
        end
      end
    end
  end

  describe '#link' do
    subject { described_class.new(context) }

    context 'when Kubernetes menu item is visible' do
      it 'menu link points to Kubernetes page' do
        expect(subject.link).to eq find_menu_item(:kubernetes).link
      end
    end

    context 'when Kubernetes menu item is not visible' do
      before do
        subject.renderable_items.delete(find_menu_item(:kubernetes))
      end

      it 'menu link points to Terraform states page' do
        expect(subject.link).to eq find_menu_item(:terraform_states).link
      end

      context 'when Terraform states menu is not visible' do
        before do
          subject.renderable_items.delete(find_menu_item(:terraform_states))
        end

        it 'menu link points to Google Cloud page' do
          expect(subject.link).to eq find_menu_item(:google_cloud).link
        end
      end
    end

    def find_menu_item(menu_item)
      subject.renderable_items.find { |i| i.item_id == menu_item }
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      it { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Kubernetes' do
      let(:item_id) { :kubernetes }

      it_behaves_like 'access rights checks'
    end

    describe 'Terraform states' do
      let(:item_id) { :terraform_states }

      it_behaves_like 'access rights checks'

      context 'if terraform_state.enabled=true' do
        before do
          stub_config(terraform_state: { enabled: true })
        end

        it_behaves_like 'access rights checks'
      end

      context 'if terraform_state.enabled=false' do
        before do
          stub_config(terraform_state: { enabled: false })
        end

        it { is_expected.to be_nil }
      end
    end

    describe 'Google Cloud' do
      let(:item_id) { :google_cloud }

      it_behaves_like 'access rights checks'

      context 'when instance is not configured for Google OAuth2' do
        before do
          unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret).new('', '')
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)
        end

        it { is_expected.to be_nil }
      end
    end

    describe 'AWS' do
      let(:item_id) { :aws }

      it_behaves_like 'access rights checks'

      context 'when feature flag is turned off globally' do
        before do
          stub_feature_flags(cloudseed_aws: false)
        end

        it { is_expected.to be_nil }

        context 'when feature flag is enabled for specific project' do
          before do
            stub_feature_flags(cloudseed_aws: project)
          end

          it_behaves_like 'access rights checks'
        end

        context 'when feature flag is enabled for specific group' do
          before do
            stub_feature_flags(cloudseed_aws: project.group)
          end

          it_behaves_like 'access rights checks'
        end

        context 'when feature flag is enabled for specific project' do
          before do
            stub_feature_flags(cloudseed_aws: user)
          end

          it_behaves_like 'access rights checks'
        end
      end
    end
  end
end

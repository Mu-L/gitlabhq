# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Labels Hierarchy', :js, feature_category: :team_planning do
  include FilteredSearchHelpers
  include ListboxHelpers

  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }

  let!(:user) { create(:user) }
  let!(:grandparent) { create(:group) }
  let!(:parent) { create(:group, parent: grandparent) }
  let!(:child) { create(:group, parent: parent) }
  let!(:project_1) { create(:project, namespace: parent) }

  let!(:grandparent_group_label) { create(:group_label, group: grandparent, title: 'Label_1') }
  let!(:parent_group_label) { create(:group_label, group: parent, title: 'Label_2') }
  let!(:child_group_label) { create(:group_label, group: child, title: 'Label_3') }
  let!(:project_label_1) { create(:label, project: project_1, title: 'Label_4') }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(work_item_view_for_issues: true)

    grandparent.add_owner(user)

    sign_in(user)
  end

  shared_examples 'assigning labels from sidebar' do
    it 'can assign all ancestors labels' do
      [grandparent_group_label, parent_group_label, project_label_1].each do |label|
        within_testid('work-item-labels') do
          click_button 'Edit'
          select_listbox_item(label.title)
          send_keys(:escape)

          expect(page).to have_link(label.title)
        end
      end
    end

    it 'does not find child group labels on dropdown' do
      within_testid('work-item-labels') do
        click_button 'Edit'

        expect_no_listbox_item(child_group_label.title)
      end
    end
  end

  shared_examples 'filtering by ancestor labels for projects' do |board = false|
    it 'filters by ancestor labels' do
      [grandparent_group_label, parent_group_label, project_label_1].each do |label|
        if board
          select_label_on_dropdown(label.title)

          expect(page).to have_selector('.board-card-title') do |card|
            expect(card).to have_selector('a', text: labeled_issue.title)
          end
        else
          within_testid('filtered-search-input') do
            click_filtered_search_bar
            click_on 'Label'
            click_on 'is ='
            click_on label.title
            send_keys :enter
          end

          expect_issues_list_count(1)
          expect(page).to have_selector('.issue-title', text: labeled_issue.title)
        end
      end
    end

    it 'does not filter by descendant group labels' do
      if board
        filtered_search.set("label=")
      else
        select_tokens 'Label', '='
      end

      expect(page).not_to have_link child_group_label.title
    end
  end

  shared_examples 'filtering by ancestor labels for groups' do |board = false|
    let(:project_2) { create(:project, namespace: parent) }
    let!(:project_label_2) { create(:label, project: project_2, title: 'Label_4') }

    let(:project_3) { create(:project, namespace: child) }
    let!(:group_label_3) { create(:group_label, group: child, title: 'Label_5') }
    let!(:project_label_3) { create(:label, project: project_3, title: 'Label_6') }

    let!(:labeled_issue_2) { create(:labeled_issue, project: project_2, labels: [grandparent_group_label, parent_group_label, project_label_2]) }
    let!(:labeled_issue_3) { create(:labeled_issue, project: project_3, labels: [grandparent_group_label, parent_group_label, group_label_3]) }

    let!(:issue_2) { create(:issue, project: project_2) }

    it 'filters by ancestors and current group labels' do
      [grandparent_group_label, parent_group_label].each do |label|
        if board
          select_label_on_dropdown(label.title)

          expect(page).to have_selector('.board-card-title') do |card|
            expect(card).to have_selector('a', text: labeled_issue.title)
          end

          expect(page).to have_selector('.board-card-title') do |card|
            expect(card).to have_selector('a', text: labeled_issue_2.title)
          end
        else
          within_testid('filtered-search-input') do
            click_filtered_search_bar
            click_on 'Label'
            click_on 'is ='
            click_on label.title
            send_keys :enter
          end

          expect_issues_list_count(3)
          expect(page).to have_selector('.issue-title', text: labeled_issue.title)
          expect(page).to have_selector('.issue-title', text: labeled_issue_2.title)
          expect(page).to have_selector('.issue-title', text: labeled_issue_3.title)
        end
      end
    end

    it 'filters by descendant group labels' do
      if board
        select_label_on_dropdown(group_label_3.title)

        expect(page).to have_selector('.board-card-title') do |card|
          expect(card).not_to have_selector('a', text: labeled_issue_2.title)
        end

        expect(page).to have_selector('.board-card-title') do |card|
          expect(card).to have_selector('a', text: labeled_issue_3.title)
        end
      else
        select_tokens 'Label', '=', group_label_3.title, submit: true

        expect_issues_list_count(1)
        expect(page).to have_selector('.issue-title', text: labeled_issue_3.title)
      end
    end

    it 'does not filter by descendant group project labels' do
      if board
        filtered_search.set("label=")

        expect(page).not_to have_selector('.btn-link', text: project_label_3.title)
      else
        select_tokens 'Label', '='

        expect(page).not_to have_link project_label_3.title
      end
    end
  end

  context 'when creating new issuable' do
    before do
      visit new_project_issue_path(project_1)
    end

    it 'is able to assign ancestor group labels' do
      fill_in 'Title', with: 'new created issue'
      fill_in 'Description', with: 'new issue description'

      within_testid('work-item-labels') do
        click_button 'Edit'
        select_listbox_item(grandparent_group_label.title)
        select_listbox_item(parent_group_label.title)
        select_listbox_item(project_label_1.title)
        send_keys(:escape)
      end

      click_button 'Create issue'

      expect(page).to have_css('h1', text: 'new created issue')
      within_testid('work-item-labels') do
        expect(page).to have_link(grandparent_group_label.title)
        expect(page).to have_link(parent_group_label.title)
        expect(page).to have_link(project_label_1.title)
      end
    end
  end

  context 'issuable sidebar' do
    let!(:issue) { create(:issue, project: project_1) }

    context 'on issue sidebar' do
      before do
        project_1.add_developer(user)

        visit project_issue_path(project_1, issue)
      end

      it_behaves_like 'assigning labels from sidebar'
    end
  end

  context 'issuable filtering' do
    let!(:labeled_issue) { create(:labeled_issue, project: project_1, labels: [grandparent_group_label, parent_group_label, project_label_1]) }
    let!(:issue) { create(:issue, project: project_1) }

    context 'on project issuable list' do
      before do
        project_1.add_developer(user)

        visit project_issues_path(project_1)
      end

      it_behaves_like 'filtering by ancestor labels for projects'

      it 'does not filter by descendant group labels' do
        select_tokens 'Label', '='

        expect(page).not_to have_link child_group_label.title
      end
    end

    context 'on group issuable list' do
      before do
        visit issues_group_path(parent)
      end

      it_behaves_like 'filtering by ancestor labels for groups'
    end
  end
end

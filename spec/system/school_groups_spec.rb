require 'rails_helper'

describe 'school groups', :school_groups, type: :system do
  let!(:user)                  { create(:user) }
  let!(:scoreboard)            { create(:scoreboard, name: 'BANES and Frome') }
  let!(:dark_sky_weather_area) { create(:dark_sky_area, title: 'BANES dark sky weather') }
  let!(:school_group)          { create(:school_group, public: public) }
  let!(:school_group_2)        { create(:school_group, public: false) }
  let(:public)                 { true }
  let!(:school_1)              { create(:school, school_group: school_group, number_of_pupils: 10) }
  let!(:school_2)              { create(:school, school_group: school_group, number_of_pupils: 20) }
  let!(:school_admin)          { create(:school_admin, school: school_1) }
  let!(:group_admin)           { create(:group_admin, school_group: school_group) }
  let!(:group_admin_2)         { create(:group_admin, school_group: school_group_2) }

  before do
    allow_any_instance_of(SchoolGroup).to receive(:fuel_types) { [:electricity, :gas, :storage_heaters] }
  end

  context 'current school group pages with feature flag set to false' do
    describe 'when not logged in' do
      it 'redirects enhanced page actions to school group page if feature is not enabled' do
        ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
          visit map_school_group_path(school_group)
          expect(current_path).to eq "/school_groups/#{school_group.slug}"
          visit comparisons_school_group_path(school_group)
          expect(current_path).to eq "/school_groups/#{school_group.slug}"
          visit priority_actions_school_group_path(school_group)
          expect(current_path).to eq "/school_groups/#{school_group.slug}"
          visit current_scores_school_group_path(school_group)
          expect(current_path).to eq "/school_groups/#{school_group.slug}"
        end
      end

      it 'does show a specific group' do
        ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
          visit school_group_path(school_group)
          expect(page).to have_content(school_1.name)
          expect(page).to have_content(school_2.name)
          expect(page).to_not have_content('Recent Usage')
          expect(page).to_not have_content('Comparisons')
          expect(page).to_not have_content('Priority Actions')
          expect(page).to_not have_content('Current Scores')
        end
      end

      it 'includes data attribute' do
        ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
          visit school_group_path(school_group)
          expect(page).to have_selector("div[data-school-group-id='#{school_group.id}']")
        end
      end

      context 'when group is public' do
        it 'shows compare link' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
            visit school_group_path(school_group)
            expect(page).to have_link("Compare schools")
          end
        end
      end
      context 'when group is private' do
        let(:public)    { false }

        it 'doesnt show compare link' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
            visit school_group_path(school_group)
            within('.application') do
              expect(page).to_not have_link("Compare schools")
            end
          end
        end
      end
    end

    describe 'when logged in as school admin' do
      before(:each) do
        sign_in(school_admin)
      end
      it 'shows compare link' do
        ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
          visit school_group_path(school_group)
          expect(page).to have_link("Compare schools")
        end
      end
    end

    describe 'when logged in' do
      before(:each) do
        sign_in(user)
      end
      context 'when group is public' do
        it 'shows compare link' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
            visit school_group_path(school_group)
            expect(page).to have_link("Compare schools")
          end
        end
      end
      context 'when group is private' do
        it 'doesnt show compare link' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'false' do
            visit school_group_path(school_group)
            expect(page).to have_link("Compare schools")
          end
        end
      end
    end
  end

  context 'enhanced school group pages with feature flag set to true' do
    context 'when not logged in' do
      context 'when school group is public' do
        let(:public) { true }

        it 'does not redirect enhanced page actions to school group page if feature is enabled or map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end

        describe '#show/recent usage' do
          it 'shows a map page with a map div and a list of schools' do
            ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
              changes = OpenStruct.new(change: "-16%")
              allow_any_instance_of(School).to receive(:recent_usage) do
                OpenStruct.new(
                  electricity: OpenStruct.new(week: changes, year: changes),
                  gas: OpenStruct.new(week: changes, year: changes),
                  storage_heaters: OpenStruct.new(week: changes, year: changes)
                )
              end
              visit school_group_path(school_group)
              expect(current_path).to eq "/school_groups/#{school_group.slug}"
              expect(find('ol.main-breadcrumbs').all('li').collect(&:text)).to eq(['Schools', school_group.name, 'Group Dashboard'])
              expect(page).to have_content('Recent Usage')
              expect(page).to have_content('Comparisons')
              expect(page).to have_content('Priority Actions')
              expect(page).to have_content('Current Scores')
              expect(page).to have_content('View map')
              expect(page).not_to have_content('View group')
              expect(page).to have_content('Scoreboard')

              # Table content
              expect(page).to have_content('Electricity')
              expect(page).to have_content('Gas')
              expect(page).to have_content('Storage heaters')
              expect(page).to have_content('School')
              expect(page).to have_content('Last week')
              expect(page).to have_content('Last year')
              expect(page).to have_content(school_1.name)
              expect(page).to have_content(school_2.name)
              expect(page).to have_content('-16%')
            end
          end
        end

        describe '#comparisons' do
          it 'shows a map page with a map div and a list of schools' do
            ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
              visit comparisons_school_group_path(school_group)
              expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
              expect(find('ol.main-breadcrumbs').all('li').collect(&:text)).to eq(['Schools', school_group.name, 'Comparisons'])
              expect(page).to have_content('Recent Usage')
              expect(page).to have_content('Comparisons')
              expect(page).to have_content('Priority Actions')
              expect(page).to have_content('Current Scores')
              expect(page).to have_content('View map')
              expect(page).not_to have_content('View group')
              expect(page).to have_content('Scoreboard')
            end
          end
        end

        describe '#priority_actions' do
          it 'shows a map page with a map div and a list of schools' do
            ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
              visit priority_actions_school_group_path(school_group)
              expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
              expect(find('ol.main-breadcrumbs').all('li').collect(&:text)).to eq(['Schools', school_group.name, 'Priority Actions'])
              expect(page).to have_content('Recent Usage')
              expect(page).to have_content('Comparisons')
              expect(page).to have_content('Priority Actions')
              expect(page).to have_content('Current Scores')
              expect(page).to have_content('View map')
              expect(page).not_to have_content('View group')
              expect(page).to have_content('Scoreboard')
            end
          end
        end

        describe '#current_scores' do
          it 'shows a map page with a map div and a list of schools' do
            ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
              visit current_scores_school_group_path(school_group)
              expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
              expect(find('ol.main-breadcrumbs').all('li').collect(&:text)).to eq(['Schools', school_group.name, 'Current Scores'])
              expect(page).to have_content('Recent Usage')
              expect(page).to have_content('Comparisons')
              expect(page).to have_content('Priority Actions')
              expect(page).to have_content('Current Scores')
              expect(page).to have_content('View map')
              expect(page).not_to have_content('View group')
              expect(page).to have_content('Scoreboard')
            end
          end
        end

        describe '#map' do
          it 'shows a map page with a map div and a list of schools' do
            ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
              visit map_school_group_path(school_group)
              expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
              expect(find('ol.main-breadcrumbs').all('li').collect(&:text)).to eq(['Schools', school_group.name, 'Map'])
              expect(page).not_to have_content('Recent Usage')
              expect(page).not_to have_content('Comparisons')
              expect(page).not_to have_content('Priority Actions')
              expect(page).not_to have_content('Current Scores')
              expect(page).to have_content('Map')
              expect(page).to have_content(school_1.name)
              expect(page).to have_content(school_2.name)
              expect(page).to have_selector(:id, 'geo-json-map')
              expect(page).not_to have_content('View map')
              expect(page).to have_content('View group')
              expect(page).to have_content('Scoreboard')
            end
          end
        end
      end

      context 'when school group is private' do
        let(:public) { false }

        it 'does not redirect enhanced page actions to school group page if feature is enabled but does redirect other actions to the map page with no view group link' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            expect(page).to_not have_content('View group')
          end
        end
      end
    end

    context 'when logged in as a school admin' do
      before(:each) do
        sign_in(school_admin)
      end

      context 'when school group is public' do
        let(:public) { true }

        it 'does not redirect enhanced page actions to school group page if feature is enabled or map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end

      context 'when school group is private' do
        let(:public) { false }

        it 'does not redirect enhanced page actions to school group page if feature is enabled and does not redirect other actions to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end
    end

    context 'when logged in as a non school admin' do
      before(:each) do
        sign_in(user)
      end

      context 'when school group is public' do
        let(:public) { true }

        it 'does not redirect enhanced page actions to school group page if feature is enabled or map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end

      context 'when school group is private' do
        let(:public) { false }

        it 'does not redirect enhanced page actions to school group page if feature is enabled and does redirect other actions to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
          end
        end
      end
    end

    context 'when logged in as a group admin' do
      before(:each) do
        sign_in(group_admin)
      end

      context 'when school group is public' do
        let(:public) { true }

        it 'does not redirect enhanced page actions to school group page if feature is enabled or redirect to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end

      context 'when school group is private' do
        let(:public) { false }

        it 'does not redirect enhanced page actions to school group page if feature is enabled and does not redirect other actions to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end
    end

    context 'when logged in as a group admin for a different group' do
      before(:each) do
        sign_in(group_admin_2) # Admin for school group 2
      end

      context 'when school group is public' do
        let(:public) { true }

        it 'does not redirect enhanced page actions to school group page if feature is enabled or redirect to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/comparisons"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/priority_actions"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/current_scores"
          end
        end
      end

      context 'when school group is private' do
        let(:public) { false }

        it 'does not redirect enhanced page actions to school group page if feature is enabled but does redirect other actions to the map page' do
          ClimateControl.modify FEATURE_FLAG_ENHANCED_SCHOOL_GROUP_DASHBOARD: 'true' do
            visit map_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit comparisons_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit priority_actions_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
            visit current_scores_school_group_path(school_group)
            expect(current_path).to eq "/school_groups/#{school_group.slug}/map"
          end
        end
      end
    end
  end
end

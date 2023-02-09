require 'rails_helper'

RSpec.describe "electricity intraday advice page", type: :system do
  let(:key) { 'electricity_intraday' }
  let(:expected_page_title) { "Electricity intraday usage analysis" }

  include_context "electricity advice page"

  context 'as school admin' do
    let(:user)  { create(:school_admin, school: school) }

    before do
      sign_in(user)
      visit school_advice_electricity_intraday_path(school)
    end

    it_behaves_like "an advice page tab", tab: "Insights"

    context "clicking the 'Insights' tab" do
      before { click_on 'Insights' }
      it_behaves_like "an advice page tab", tab: "Insights"
    end

    context "clicking the 'Analysis' tab" do
      before do
        click_on 'Analysis'
      end

      it_behaves_like "an advice page tab", tab: "Analysis"

      it "shows titles" do
        expect(page).to have_content("Electricity consumption during the school day over the last 12 months")
      end

      it "shows dates for 7 day period up to end date" do
        expected_start_date = (end_date - 6.days).to_s(:es_short)
        expected_end_date = end_date.to_s(:es_short)
        expect(page).to have_content("graph shows how the electricity consumption for your school varies during the day between #{expected_start_date} and #{expected_end_date}")
      end

      context 'when not enough data' do
        let(:start_date) { end_date - 11.months}
        it "shows message" do
          expect(page).to have_content("Not enough data to run analysis")
        end
      end
    end

    context "clicking the 'Learn More' tab" do
      before { click_on 'Learn More' }
      it_behaves_like "an advice page tab", tab: "Learn More"
    end
  end
end

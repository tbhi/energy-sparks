require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe "with valid attributes" do
    subject { create :issue }
    it { is_expected.to be_valid }
  end

  describe "#issue_type" do
    it "is issue by default" do
      expect(Issue.new(issue_type: nil).issue_type).to eq('issue')
    end
    it "can be set" do
      expect(Issue.new(issue_type: :note).issue_type).to eq('note')
    end
  end

  describe "#status" do
    it "is open by default" do
      expect(Issue.new(status: nil).status).to eq('open')
    end
    it "can be set" do
      expect(Issue.new(status: :closed).status).to eq('closed')
    end
  end

  describe "#status_summary" do
    subject(:status_summary) { issue.status_summary }
    context "closed issue" do
      let(:issue) { build(:issue, issue_type: :issue, status: :closed) }
      it { expect(status_summary).to eq("closed issue") }
    end
    context "open issue" do
      let(:issue) { build(:issue, issue_type: :issue, status: :open) }
      it { expect(status_summary).to eq("open issue") }
    end
    context "note" do
      let(:issue) { build(:issue, issue_type: :note, status: :open) }
      it { expect(status_summary).to eq("note") }
    end
  end

  describe "before_save :set_note_status" do
    before do
      issue.save
    end
    context "issue is a note" do
      subject(:issue) { build(:issue, issue_type: :note, status: :closed) }
      it "is sets status to open when saved" do
        expect(issue).to be_status_open
      end
    end
    context "issue is an issue" do
      subject(:issue) { build(:issue, issue_type: :issue, status: :closed) }
      it "is does not change status" do
        expect(issue).to be_status_closed
      end
    end
  end

  describe "validate :school_issue_meters_only" do
    let(:meter) { create(:gas_meter) }
    before do
      issue.meters << meter
      issue.save
    end
    context "issueable is a school" do
      subject(:issue) { create(:issue, issueable: create(:school)) }
      it { expect(issue).to be_valid }
    end
    context "issueable is a school group" do
      subject(:issue) { create(:issue, issueable: create(:school_group)) }
      it { expect(issue).to_not be_valid }
      it { expect(issue.errors.messages[:base]).to include("Only school issues can have associated meters") }
    end
    context "issueable is a data source" do
      subject(:issue) { create(:issue, issueable: create(:data_source)) }
      it { expect(issue).to_not be_valid }
      it { expect(issue.errors.messages[:base]).to include("Only school issues can have associated meters") }
    end
  end

  describe "#resolve!" do
    let!(:user) { create(:admin) }
    context "when issue is of type note" do
      subject(:issue) { create(:issue, issue_type: :note) }
      it { expect(issue.resolve!(updated_by: user)).to be_falsey }
      before do
        issue.resolve!(updated_by: user)
      end
      it { expect(issue).to be_status_open }
      it { expect(issue.updated_by).to eq(user) }
    end
    context "when issue is of type issue" do
      subject(:issue) { create(:issue, issue_type: :issue) }
      it { expect(issue.resolve!(updated_by: user)).to be_truthy }
      before do
        issue.resolve!(updated_by: user)
      end
      it { expect(issue).to be_status_closed }
      it { expect(issue.updated_by).to eq(user) }
    end
  end

  describe ".for_school_group" do
    let!(:school_group) { create(:school_group) }
    let!(:school) { create(:school, school_group: school_group) }

    context "when there are issues for school group and schools in group" do
      let!(:school_issue) { create(:issue, issueable: school) }
      let!(:school_group_issue) { create(:issue, issueable: school_group) }
      let!(:different_school_in_school_group_issue) { create(:issue, issueable: create(:school, school_group: school_group)) }

      subject(:issues) { Issue.for_school_group(school_group) }

      it { expect(issues.count).to eq(3) }
      it { expect(issues).to include(school_issue) }
      it { expect(issues).to include(school_group_issue) }
      it { expect(issues).to include(different_school_in_school_group_issue) }

      context "and issues for different school group" do
        let!(:different_school_group_issue) { create(:issue, issueable: create(:school_group)) }
        it { expect(issues.count).to eq(3) }
        it { expect(issues).to_not include(different_school_group_issue) }
      end
      context "and issues for schools in other groups" do
        let!(:different_school_group_school_issue) { create(:issue, issueable: create(:school)) }
        it { expect(issues.count).to eq(3) }
        it { expect(issues).to_not include(different_school_group_school_issue) }
      end
    end
  end
end

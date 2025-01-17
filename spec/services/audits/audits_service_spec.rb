require 'rails_helper'

describe Audits::AuditService, type: :service do
  let(:school)            { create(:school) }
  let(:service)           { described_class.new(school) }

  describe '#recent_audit' do
    let(:created_at)       { Date.yesterday }
    let(:published)        { true }
    let!(:audit)           { create(:audit, school: school, created_at: created_at, published: published) }

    context 'a recent one' do
      it 'is returned' do
        expect(service.recent_audit).to eql audit
      end
    end

    context 'an old one' do
      let(:created_at) { Time.zone.today.last_year }

      it 'is ignored' do
        expect(service.recent_audit).to be_nil
      end
    end

    context 'an unpublished one' do
      let(:published) { false }

      it 'is ignored' do
        expect(service.recent_audit).to be_nil
      end
    end
  end

  describe '#last_audit' do
    let!(:published_audit)            { create(:audit, school: school, published: true, created_at: 3.days.ago) }
    let!(:older_published_audit)      { create(:audit, school: school, published: true, created_at: 4.days.ago) }

    it 'returns most recent audit' do
      expect(service.last_audit).to eql published_audit
    end

    context 'excluding unpuplished audits' do
      let!(:unpulished_audit) { create(:audit, school: school, published: false, created_at: 2.days.ago) }

      it 'returns published audit' do
        expect(service.last_audit).to eql published_audit
      end
    end
  end

  describe '#process' do
    let(:audit) { build(:audit, school: school) }

    it 'saves audit' do
      service.process(audit)
      expect(audit).to be_persisted
    end

    it 'only create observation if valid' do
      audit.school = nil
      service.process(audit)
      expect(audit).not_to be_persisted
    end

    it 'creates observation when saving audit' do
      expect { service.process(audit) }.to change(Observation, :count).from(0).to(1)
      expect(Observation.first.audit).to eql audit
      expect(Observation.first.points).not_to be_nil
      expect(Observation.first.audit?).to be true
    end
  end
end

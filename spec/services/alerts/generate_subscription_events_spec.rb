require 'rails_helper'

describe Alerts::GenerateSubscriptionEvents do

  let(:school)                  { create(:school) }
  let(:rating)                  { 5.0 }
  let(:alert_type)              { create(:alert_type, frequency: :weekly) }
  let!(:alert)                  { create(:alert, school: school, rating: rating, alert_type: alert_type) }
  let(:content_generation_run)  { create(:content_generation_run, school: school) }
  let(:service)                 { Alerts::GenerateSubscriptionEvents.new(school, content_generation_run: content_generation_run) }
  let(:weekly_alerts)           { school.alerts.joins(:alert_type).where(alert_types: { frequency: [:weekly] }) }

  context 'no alerts' do
    it 'does nothing, no events created' do
      service.perform(weekly_alerts)
      expect(content_generation_run.alert_subscription_events.count).to eq 0
    end
  end

  context 'alerts, but no subscriptions' do
    it 'does nothing, no events created' do
      create(:alert, school: school)
      service.perform(weekly_alerts )
      expect(content_generation_run.alert_subscription_events.count).to eq 0
    end
  end

  context 'alerts and subscriptions' do
    let(:sms_active)                { true }
    let(:email_active)              { true }
    let!(:alert_type_rating)        { create :alert_type_rating, alert_type: alert.alert_type, rating_from: 1, rating_to: 6, sms_active: sms_active, email_active: email_active}

    let!(:email_contact)            { create(:contact_with_name_email, school: school) }
    let!(:sms_contact)              { create(:contact_with_name_phone, school: school) }
    let!(:sms_and_email_contact)    { create(:contact_with_name_email_phone, school: school) }

    let(:termly_alerts)           { school.alerts.joins(:alert_type).where(alert_types: { frequency: [:termly] }) }
    let(:no_frequency_alerts)     { school.alerts.joins(:alert_type).where(alert_types: { frequency: [] }) }

    context 'contacts with email, sms and both' do

      context 'with some content' do

        let!(:content_version){ create :alert_type_rating_content_version, alert_type_rating: alert_type_rating }

        it 'does not process anything the frequency is set to empty' do
          expect { service.perform(no_frequency_alerts)}.to_not change { content_generation_run.alert_subscription_events.count }
        end

        it 'does not process anything the frequency is set to a different frequency' do
          expect { service.perform(termly_alerts)}.to_not change { content_generation_run.alert_subscription_events.count }
        end

        it 'assigns a find out more from the run, if it matches the content version' do
          find_out_more = create(:find_out_more, content_version: content_version, alert: alert, content_generation_run: content_generation_run)

          service.perform(weekly_alerts)
          alert_subscription_event = content_generation_run.alert_subscription_events.first
          expect(alert_subscription_event.find_out_more).to eq(find_out_more)
          expect(alert_subscription_event.priority).to eq(0.15)
        end

        it 'does not assign the find out more if it is from different content' do
          content_version_2 = create :alert_type_rating_content_version, alert_type_rating: alert_type_rating
          find_out_more = create(:find_out_more, content_version: content_version_2, alert: alert, content_generation_run: content_generation_run)

          service.perform(weekly_alerts)
          alert_subscription_event = content_generation_run.alert_subscription_events.first
          expect(alert_subscription_event.find_out_more).to be_nil
        end

        it 'creates events and associates the content versions' do
          expect { service.perform(weekly_alerts)}.to change { content_generation_run.alert_subscription_events.count }.by(4)

          expect(email_contact.alert_subscription_events.count).to eq 1
          expect(email_contact.alert_subscription_events.first.communication_type).to eq 'email'
          expect(email_contact.alert_subscription_events.first.content_version).to eq content_version
          expect(email_contact.alert_subscription_events.first.unsubscription_uuid).to_not be_nil
          expect(sms_contact.alert_subscription_events.count).to eq 1
          expect(sms_contact.alert_subscription_events.first.communication_type).to eq 'sms'
          expect(sms_contact.alert_subscription_events.first.content_version).to eq content_version
          expect(sms_and_email_contact.alert_subscription_events.count).to eq 2
          expect(sms_and_email_contact.alert_subscription_events.pluck(:communication_type)).to match_array ['sms','email']
        end

        it 'does not create any events for the scope if there is an unsubscription record that matches the rating' do
          create :alert_type_rating_unsubscription, contact: email_contact, alert_type_rating: alert_type_rating, scope: :email

          expect { service.perform(weekly_alerts)}.to change { content_generation_run.alert_subscription_events.count }.by(3)

          expect(email_contact.alert_subscription_events.count).to eq 0
          expect(sms_contact.alert_subscription_events.count).to eq 1
          expect(sms_and_email_contact.alert_subscription_events.count).to eq 2
          expect(sms_and_email_contact.alert_subscription_events.pluck(:communication_type)).to match_array ['email', 'sms']
        end

        it 'ignores if events already exist' do
          existing_event = AlertSubscriptionEvent.create!(alert: alert, contact: email_contact, status: :sent, communication_type: :email, content_generation_run: ContentGenerationRun.create(school: school), content_version: content_version)
          expect(AlertSubscriptionEvent.count).to eq 1
          service.perform(weekly_alerts)
          expect(content_generation_run.alert_subscription_events.count).to eq 3
          expect(content_generation_run.alert_subscription_events.all?(&:pending?)).to eq true
          existing_event.reload
          expect(existing_event.status).to eq 'sent'
        end

        context 'where SMS content is inactive' do
          let(:sms_active){ false }
          it 'does not create events for that type' do
            service.perform(weekly_alerts)
            expect(email_contact.alert_subscription_events.count).to eq 1
            expect(sms_contact.alert_subscription_events.count).to eq 0
            expect(sms_and_email_contact.alert_subscription_events.count).to eq 1
          end
        end

        context 'where email content is inactive' do
          let(:email_active){ false }
          it 'does not create events for that type' do
            service.perform(weekly_alerts)
            expect(email_contact.alert_subscription_events.count).to eq 0
            expect(sms_contact.alert_subscription_events.count).to eq 1
            expect(sms_and_email_contact.alert_subscription_events.count).to eq 1
          end
        end

      end

    end
  end
end

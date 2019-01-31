module Alerts
  class GenerateSubscriptionEvents
    def initialize(school)
      @school = school
    end

    def perform
      @school.alerts.latest.each do |alert|
        process_alert(alert)
      end
    end

  private

    def process_alert(alert)
      if any_subscriptions?(@school, alert.alert_type)
        process_subscriptions(alert)
      end
    end

    def process_subscriptions(alert)
      subscriptions(@school, alert.alert_type).each do |subscription|
        subscription.contacts.each do |contact|
          AlertSubscriptionEvent.where(contact: contact, alert: alert, alert_subscription: subscription).first_or_create!
        end
      end
    end

    def any_subscriptions?(school, alert_type)
      subscriptions(school, alert_type).any?
    end

    def subscriptions(school, alert_type)
      school.alert_subscriptions.where(alert_type: alert_type)
    end
  end
end

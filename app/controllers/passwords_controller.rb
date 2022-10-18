class PasswordsController < Devise::PasswordsController
  before_action :set_confirmed

  include AlertContactCreator
  include NewsletterSubscriber

  def edit
    super
    # the resource is NOT the actual user - have to find it ourselves
    user = User.with_reset_password_token(params[:reset_password_token])
    @allow_subscriptions = allow_subscriptions?(user)
    @subscribe_alerts = true
    @subscribe_newsletters = true
  end

  def update
    super do |resource|
      @allow_subscriptions = allow_subscriptions?(resource)
      @subscribe_alerts = auto_create_alert_contact?
      @subscribe_newsletters = auto_subscribe_newsletter?
      if resource.errors.empty? && @allow_subscriptions
        create_or_update_alert_contact(resource.school, resource) if @subscribe_alerts
        subscribe_newsletter(resource.school, resource) if @subscribe_newsletters
      end
    end
  end

  private

  def set_confirmed
    @confirmed = (params[:confirmed] == 'true')
  end

  def allow_subscriptions?(user)
    @confirmed && user && user.school_id.present?
  end
end
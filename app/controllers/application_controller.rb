class ApplicationController < ActionController::Base
  include DefaultUrlOptionsHelper

  protect_from_forgery with: :exception
  around_action :switch_locale
  before_action :authenticate_user!
  before_action :analytics_code
  before_action :pagy_locale
  before_action :check_admin_mode
  helper_method :site_settings, :current_school_podium, :current_user_school

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  def after_sign_in_path_for(user)
    if EnergySparks::FeatureFlags.active?(:redirect_to_preferred_locale)
      subdomain = ApplicationController.helpers.subdomain_for(user.preferred_locale)
      root_url(subdomain: subdomain).chomp('/') + session.fetch(:user_return_to, '/')
    else
      session.fetch(:user_return_to, root_url)
    end
  end

  def switch_locale(&action)
    locale = LocaleFinder.new(params, request).locale
    I18n.with_locale(locale, &action)
  end

  def route_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  def site_settings
    @site_settings ||= SiteSettings.current
  end

  def current_school_podium
    if @school && @school.scoreboard
      @school_podium ||= Podium.create(school: @school, scoreboard: @school.scoreboard)
    end
  end

  def current_user_school
    if current_user && current_user.school
      current_user.school
    end
  end

  def current_ip_address
    request.remote_ip
  end

  private

  def check_admin_mode
    if admin_mode? && !current_user_admin? && !login_page?
      render 'home/maintenance', layout: false
    end
  end

  def admin_mode?
    ENV["ADMIN_MODE"] == 'true'
  end

  def current_user_admin?
    current_user.present? && current_user.admin?
  end

  def login_page?
    controller_name == 'sessions'
  end

  def analytics_code
    @analytics_code ||= ENV['GOOGLE_ANALYTICS_CODE']
  end

  def pagy_locale
    @pagy_locale = I18n.locale.to_s
  end

  def header_fix_enabled
    @header_fix_enabled = true
  end
end

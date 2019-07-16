class SchoolCreator
  def initialize(school)
    @school = school
  end

  def onboard_school!(onboarding)
    if @school.valid?
      @school.update!(
        school_group: onboarding.school_group,
        calendar_area: onboarding.calendar_area,
        solar_pv_tuos_area: onboarding.solar_pv_tuos_area,
        weather_underground_area: onboarding.weather_underground_area,
        dark_sky_area: onboarding.dark_sky_area
      )
      @school.transaction do
        record_event(onboarding, :school_admin_created) do
          onboarding.created_user.update!(school: @school, role: :school_admin)
        end
        record_events(onboarding, :default_school_times_added, :default_alerts_assigned) do
          process_new_school!
        end
        process_new_configuration!
        record_event(onboarding, :school_calendar_created) if @school.calendar
        record_event(onboarding, :school_details_created) do
          onboarding.update!(school: @school)
        end
      end
    end
    @school
  end

  def process_new_school!
    add_school_times
  end

  def activate_school!
    @school.update!(active: true)
    if should_send_activation_email?
      OnboardingMailer.with(school_onboarding: @school.school_onboarding).activation_email.deliver_now
      record_event(@school.school_onboarding, :activation_email_sent)
    end
  end

  def add_school_times
    SchoolTime.days.each do |day, _value|
      @school.school_times.create(day: day)
    end
  end

  def process_new_configuration!
    generate_calendar
    generate_configuration
  end

private

  def should_send_activation_email?
    @school.school_onboarding && !@school.school_onboarding.has_event?(:activation_email_sent)
  end

  def generate_calendar
    if (area = @school.calendar_area)
      if (template = area.calendars.find_by(template: true))
        calendar = CalendarFactory.new(template, @school.name).create
        @school.update!(calendar: calendar)
      end
    end
  end

  def generate_configuration
    Schools::Configuration.create!(school: @school)
  end

  def record_event(onboarding, *events)
    result = yield if block_given?
    events.each do |event|
      onboarding.events.create(event: event)
    end
    result
  end
  alias_method :record_events, :record_event
end

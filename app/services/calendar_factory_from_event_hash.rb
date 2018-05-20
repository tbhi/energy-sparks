class CalendarFactoryFromEventHash
  def initialize(event_hash, area, template = false)
    @event_hash = event_hash
    @area = area
    @template = template
  end

  def create
    @calendar = Calendar.where(default: @template, area: @area, title: @area.title, template: @template).first_or_create

    CalendarEventTypeFactory.create

    @event_hash.each do |event|
      event_type = CalendarEventType.select { |cet| event[:term].include? cet.title }.first

      academic_year = AcademicYear.where('start_date <= ? and end_date >= ?', Date.parse(event[:start_date]), Date.parse(event[:start_date])).first
      @calendar.calendar_events.create(title: event[:term], start_date: event[:start_date], end_date: event[:end_date], calendar_event_type: event_type, academic_year: academic_year)
    end

    create_bank_holidays
    create_dummy_inset_day
    create_holidays_between_terms
    @calendar
  end

private

  def create_holidays_between_terms
    HolidayFactory.new(@calendar).create
  end

  def create_dummy_inset_day
    inset_day_type = CalendarEventType.find_by(title: CalendarEventType::INSET_DAY)
    @calendar.calendar_events.create(title: CalendarEventType::INSET_DAY, start_date: '2018-07-01', end_date: '2018-07-01', calendar_event_type: inset_day_type, academic_year: AcademicYear.find_by(start_date: '01-09-2018'))
  end

  def create_bank_holidays
    find_bank_holidays(@area).each do |bh|
      calendar_event_type = CalendarEventType.find_by(description: bh.title)
      @calendar.calendar_events.create(title: bh.title, start_date: bh.holiday_date, end_date: bh.holiday_date, calendar_event_type: calendar_event_type)
    end
  end

  def find_bank_holidays(area)
    bhs = BankHoliday.where(area: area)
    return bhs if bhs.any?
    find_bank_holidays(area.parent_area)
  end
end

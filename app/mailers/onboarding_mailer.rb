class OnboardingMailer < LocaleMailer
  helper :application

  def onboarding_email
    @school_onboarding = params[:school_onboarding]
    @title = @school_onboarding.school_name
    locales = @school_onboarding.email_locales
    @body = for_each_locale(locales) { render :onboarding_email_content, layout: nil }.join("<hr>")
    @subject = for_each_locale(locales) { default_i18n_subject }.join(" / ")
    make_bootstrap_mail(to: @school_onboarding.contact_email, subject: @subject)
  end

  def completion_email
    @school_onboarding = params[:school_onboarding]
    @title = @school_onboarding.school_name
    @school_group_name = @school_onboarding.school&.school_group&.name
    if @school_onboarding.created_by
      make_bootstrap_mail(to: 'operations@energysparks.uk', subject:
        default_i18n_subject(school: @school_onboarding.school_name, school_group: @school_group_name))
    end
  end

  def reminder_email
    email = params[:email]
    @onboardings = params[:onboardings]
    raise "onboardings contains contact emails that don't match email parameter" if @onboardings.pluck(:contact_email).uniq != [email]
    locales = @onboardings.reduce([]) { |memo, onboarding| memo.union(onboarding.email_locales) }
    @body = for_each_locale(locales) { render :reminder_email_content, layout: nil }.join("<hr>")
    subject = for_each_locale(locales) { default_i18n_subject(count: @onboardings.count) }.join(" / ")
    make_bootstrap_mail(to: email, subject: subject)
  end

  def activation_email
    @school = params[:school]
    @title = @school.name
    @to = user_emails(params[:users])
    make_bootstrap_mail(to: @to, subject: default_i18n_subject(school: @school.name, locale: locale_param))
  end

  def onboarded_email
    @school = params[:school]
    @title = @school.name
    @to = user_emails(params[:users])
    make_bootstrap_mail(to: @to, subject: default_i18n_subject(school: @school.name, locale: locale_param))
  end

  def data_enabled_email
    @school = params[:school]
    @title = @school.name
    @to = user_emails(params[:users])
    @target_prompt = params[:target_prompt]
    make_bootstrap_mail(to: @to, subject: default_i18n_subject(school: @school.name, locale: locale_param))
  end

  def welcome_email
    @school = params[:school]
    @title = @school.name
    @to = user_emails(params[:users])
    make_bootstrap_mail(to: @to)
  end
end

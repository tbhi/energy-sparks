module LocaleHelper
  def t_field(sym, locale)
    "#{sym}_#{Mobility.normalize_locale(locale)}".to_sym
  end

  def t_params(fields, locales = I18n.available_locales)
    locales.map do |locale|
       fields.map do |field|
         t_field(field, locale)
       end
    end.flatten
  end
end
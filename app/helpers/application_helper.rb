module ApplicationHelper
  def nice_date_times(datetime)
    return "" if datetime.nil?
    "#{datetime.strftime('%a')} #{datetime.day.ordinalize} #{datetime.strftime('%b %Y %H:%M')} "
  end

  def nice_dates(date)
    return "" if date.nil?
    "#{date.strftime('%a')} #{date.day.ordinalize} #{date.strftime('%b %Y')} "
  end

  def active(bool = true)
    bool ? '' : 'bg-warning'
  end

  def html_from_markdown(folder, file)
    folder_dir = Rails.root.join('markdown_pages').join(folder.to_s)
    if File.exist? folder_dir
      file_name = file.nil? ? 'default.md' : file + '.md'
      full_path = folder_dir.join file_name
      return "Sorry, we couldn't find that page. [File not found]" unless File.exist? full_path
      render_markdown File.read(full_path)
    else
      "Sorry, we couldn't find that page. [Folder not found]"
    end
  end

  def render_markdown(content)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, autolink: true)
    markdown.render(content).html_safe
  end

  def options_from_collection_for_select_with_data(collection, value_method, text_method, selected = nil, data = {})
    options = collection.map do |element|
      [element.send(text_method), element.send(value_method), data.map do |k, v|
        { "data-#{k}" => element.send(v) }
      end
      ].flatten
    end
    selected, disabled = extract_selected_and_disabled(selected)
    select_deselect = {}
    select_deselect[:selected] = extract_values_from_collection(collection, value_method, selected)
    select_deselect[:disabled] = extract_values_from_collection(collection, value_method, disabled)

    options_for_select(options, select_deselect)
  end

  def class_for_last_date(last_date)
    if last_date.nil?
      "table-light"
    elsif last_date < Time.zone.now - 30.days
      "table-danger"
    elsif last_date < Time.zone.now - 5.days
      "table-warning"
    else
      "table-success"
    end
  end

  def nav_link(link_text, link_path)
    content_tag(:li) do
      if current_page?(link_path)
        link_to link_text, link_path, class: 'nav-link active'
      else
        link_to link_text, link_path, class: 'nav-link'
      end
    end
  end
end

module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def header_title(page_title)
    content_for(:header_title) { page_title }
  end

  def permitted_accountable_partial(name)
    name.underscore
  end

  def notification(text, **options, &block)
    content = tag.p(text)
    content = capture &block if block_given?

    render partial: "shared/notification", locals: { type: options[:type], content: content }
  end

  # Wrap view with <%= modal do %> ... <% end %> to have it open in a modal
  # Make sure to add data-turbo-frame="modal" to the link/button that opens the modal
  def modal(&block)
    content = capture &block
    render partial: "shared/modal", locals: { content: content }
  end

  def currency_dropdown(f: nil, options: [])
    render partial: "shared/currency_dropdown", locals: { f: f, options: options }
  end

  def sidebar_link_to(name, path, options = {})
    base_class_names = [ "block", "border", "border-transparent", "rounded-xl", "-ml-2", "p-2", "text-sm", "font-medium", "text-gray-500", "flex", "items-center" ]
    hover_class_names = [ "hover:bg-white", "hover:border-alpha-black-50", "hover:text-gray-900", "hover:shadow-xs" ]
    current_page_class_names = [ "bg-white", "border-alpha-black-50", "text-gray-900", "shadow-xs" ]

    link_class_names = if current_page?(path) || (request.path.start_with?(path) && path != "/")
                         base_class_names.delete("border-transparent")
                         base_class_names + hover_class_names + current_page_class_names
    else
                         base_class_names + hover_class_names
    end

    merged_options = options.reverse_merge(class: link_class_names.join(" ")).except(:icon)

    link_to path, merged_options do
      lucide_icon(options[:icon], class: "w-5 h-5 mr-2") + name
    end
  end

  # Styles to use when displaying a change in value
  def trend_styles(trend)
    bg_class, text_class, symbol, icon = case trend.direction
    when "up"
      [ "bg-green-500/5", "text-green-500", "+", "arrow-up" ]
    when "down"
      [ "bg-red-500/5", "text-red-500", "-", "arrow-down" ]
    when "flat"
      [ "bg-gray-500/5", "text-gray-500", "", "minus" ]
    else
      raise ArgumentError, "Invalid trend direction: #{trend.direction}"
    end

    { bg_class: bg_class, text_class: text_class, symbol: symbol, icon: icon }
  end

  def trend_label(period)
    return "since account creation" if period.date_range.nil?
    start_date, end_date = period.date_range.first, period.date_range.last

    return "Starting from #{start_date.strftime('%b %d, %Y')}" if end_date.nil?
    return "Ending at #{end_date.strftime('%b %d, %Y')}" if start_date.nil?

    days_apart = (end_date - start_date).to_i

    case days_apart
    when 1
      "vs. yesterday"
    when 7
      "vs. last week"
    when 30, 31
      "vs. last month"
    when 365, 366
      "vs. last year"
    else
      "from #{start_date.strftime('%b %d, %Y')} to #{end_date.strftime('%b %d, %Y')}"
    end
  end

  def format_currency(number, options = {})
    user_currency_preference = Current.family.try(:currency) || "USD"

    currency_options = CURRENCY_OPTIONS[user_currency_preference.to_sym]
    options.reverse_merge!(currency_options)

    number_to_currency(number, options)
  end
end

module ApplicationHelper
  include Pagy::Frontend

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

  def account_groups
    assets, liabilities = Current.family.accounts.by_group(currency: Current.family.currency, period: Period.last_30_days).values_at(:assets, :liabilities)
    [ assets.children, liabilities.children ].flatten
  end

  def sidebar_modal(&block)
    content = capture &block
    render partial: "shared/sidebar_modal", locals: { content: content }
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

  def trend_styles(trend)
    fallback = { bg_class: "bg-gray-500/5", text_class: "text-gray-500", symbol: "", icon: "minus" }
    return fallback if trend.nil? || trend.direction == "flat"

    bg_class, text_class, symbol, icon = case trend.direction
    when "up"
      trend.type == "liability" ? [ "bg-red-500/5", "text-red-500", "+", "arrow-up" ] : [ "bg-green-500/5", "text-green-500", "+", "arrow-up" ]
    when "down"
      trend.type == "liability" ? [ "bg-green-500/5", "text-green-500", "-", "arrow-down" ] : [ "bg-red-500/5", "text-red-500", "-", "arrow-down" ]
    when "flat"
      [ "bg-gray-500/5", "text-gray-500", "", "minus" ]
    else
      raise ArgumentError, "Invalid trend direction: #{trend.direction}"
    end

    { bg_class: bg_class, text_class: text_class, symbol: symbol, icon: icon }
  end

  def period_label(period)
    return "since account creation" if period.date_range.begin.nil?
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

  def format_money(number_or_money, options = {})
    money = Money.new(number_or_money)
    options.reverse_merge!(money.default_format_options)
    number_to_currency(money.amount, options)
  end

  def format_money_without_symbol(number_or_money, options = {})
    money = Money.new(number_or_money)
    options.reverse_merge!(money.default_format_options)
    ActiveSupport::NumberHelper.number_to_delimited(money.amount.round(options[:precision] || 0), { delimiter: options[:delimiter], separator: options[:separator] })
  end
end

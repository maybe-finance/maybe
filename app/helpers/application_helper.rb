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

  def family_notifications_stream
    turbo_stream_from [ Current.family, :notifications ] if Current.family
  end

  def family_stream
    turbo_stream_from Current.family if Current.family
  end

  def render_flash_notifications
    notifications = flash.flat_map do |type, message_or_messages|
      Array(message_or_messages).map do |message|
        render partial: "shared/notification", locals: { type: type, message: message }
      end
    end

    safe_join(notifications)
  end

  ##
  # Helper to open a centered and overlayed modal with custom contents
  #
  # @example Basic usage
  #   <%= modal classes: "custom-class" do %>
  #     <div>Content here</div>
  #   <% end %>
  #
  def modal(options = {}, &block)
    content = capture &block
    render partial: "shared/modal", locals: { content:, classes: options[:classes] }
  end

  ##
  # Helper to open a drawer on the right side of the screen with custom contents
  #
  # @example Basic usage
  #   <%= drawer do %>
  #     <div>Content here</div>
  #   <% end %>
  #
  def drawer(&block)
    content = capture &block
    render partial: "shared/drawer", locals: { content: content }
  end

  def disclosure(title, &block)
    content = capture &block
    render partial: "shared/disclosure", locals: { title: title, content: content }
  end

  def sidebar_link_to(name, path, options = {})
    is_current = current_page?(path) || (request.path.start_with?(path) && path != "/")

    classes = [
      "flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium text-gray-500",
      (is_current ? "bg-white text-gray-900 shadow-xs border-alpha-black-50" : "hover:bg-gray-100 border-transparent")
    ].compact.join(" ")

    link_to path, **options.merge(class: classes), aria: { current: ("page" if current_page?(path)) } do
      concat(lucide_icon(options[:icon], class: "w-5 h-5")) if options[:icon]
      concat(name)
    end
  end

  def mixed_hex_styles(hex)
    color = hex || "#1570EF" # blue-600

    <<-STYLE.strip
      background-color: color-mix(in srgb, #{color} 5%, white);
      border-color: color-mix(in srgb, #{color} 10%, white);
      color: #{color};
    STYLE
  end

  def circle_logo(name, hex: nil, size: "md")
    render partial: "shared/circle_logo", locals: { name: name, hex: hex, size: size }
  end

  def return_to_path(params, fallback = root_path)
    uri = URI.parse(params[:return_to] || fallback)
    uri.relative? ? uri.path : root_path
  end

  def trend_styles(trend)
    fallback = { bg_class: "bg-gray-500/5", text_class: "text-gray-500", symbol: "", icon: "minus" }
    return fallback if trend.nil? || trend.direction.flat?

    bg_class, text_class, symbol, icon = case trend.direction
    when "up"
      trend.favorable_direction.down? ? [ "bg-red-500/5", "text-red-500", "+", "arrow-up" ] : [ "bg-green-500/5", "text-green-500", "+", "arrow-up" ]
    when "down"
      trend.favorable_direction.down? ? [ "bg-green-500/5", "text-green-500", "-", "arrow-down" ] : [ "bg-red-500/5", "text-red-500", "-", "arrow-down" ]
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
    return nil unless number_or_money

    money = Money.new(number_or_money)
    options.reverse_merge!(money.format_options(I18n.locale))
    number_to_currency(money.amount, options)
  end

  def format_money_without_symbol(number_or_money, options = {})
    return nil unless number_or_money

    money = Money.new(number_or_money)
    options.reverse_merge!(money.format_options(I18n.locale))
    ActiveSupport::NumberHelper.number_to_delimited(money.amount.round(options[:precision] || 0), { delimiter: options[:delimiter], separator: options[:separator] })
  end

  def totals_by_currency(collection:, money_method:, separator: " | ", negate: false)
    collection.group_by(&:currency)
              .transform_values { |item| negate ? item.sum(&money_method) * -1 : item.sum(&money_method) }
              .map { |_currency, money| format_money(money) }
              .join(separator)
  end
end

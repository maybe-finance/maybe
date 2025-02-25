module ApplicationHelper
  include Pagy::Frontend

  def icon(key, size: "md", color: "current")
    render partial: "shared/icon", locals: { key:, size:, color: }
  end

  # Convert alpha (0-1) to 8-digit hex (00-FF)
  def hex_with_alpha(hex, alpha)
    alpha_hex = (alpha * 255).round.to_s(16).rjust(2, "0")
    "#{hex}#{alpha_hex}"
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def header_title(page_title)
    content_for(:header_title) { page_title }
  end

  def header_description(page_description)
    content_for(:header_description) { page_description }
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
  def drawer(reload_on_close: false, &block)
    content = capture &block
    render partial: "shared/drawer", locals: { content:, reload_on_close: }
  end

  def disclosure(title, default_open: true, &block)
    content = capture &block
    render partial: "shared/disclosure", locals: { title: title, content: content, open: default_open }
  end

  def page_active?(path)
    current_page?(path) || (request.path.start_with?(path) && path != "/")
  end

  def mixed_hex_styles(hex)
    color = hex || "#1570EF" # blue-600

    <<-STYLE.strip
      background-color: color-mix(in srgb, #{color} 10%, white);
      border-color: color-mix(in srgb, #{color} 30%, white);
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

  # Wrapper around I18n.l to support custom date formats
  def format_date(object, format = :default, options = {})
    date = object.to_date

    format_code = options[:format_code] || Current.family&.date_format

    if format_code.present?
      date.strftime(format_code)
    else
      I18n.l(date, format: format, **options)
    end
  end

  def format_money(number_or_money, options = {})
    return nil unless number_or_money

    Money.new(number_or_money).format(options)
  end

  def totals_by_currency(collection:, money_method:, separator: " | ", negate: false)
    collection.group_by(&:currency)
              .transform_values { |item| calculate_total(item, money_method, negate) }
              .map { |_currency, money| format_money(money) }
              .join(separator)
  end

  def show_super_admin_bar?
    if params[:admin].present?
      cookies.permanent[:admin] = params[:admin]
    end

    cookies[:admin] == "true"
  end

  # Helper method to get the current breadcrumbs
  # @return [Array<Array<String, String>>] The breadcrumbs array
  def current_breadcrumbs
    return @breadcrumbs if @breadcrumbs.present?

    # Default breadcrumbs based on controller name
    case controller_name
    when "pages"
      [ [ "Home", root_path ] ]
    when "transactions"
      [ [ "Transactions", transactions_path ] ]
    when "budgets"
      [ [ "Budgets", budgets_path ] ]
    else
      # For other controllers, try to determine the parent section
      if controller_path.start_with?("transactions/") || controller_name.include?("transaction")
        [ [ "Transactions", transactions_path ], [ controller_name.titleize, nil ] ]
      elsif controller_path.start_with?("budgets/") || controller_name.include?("budget")
        [ [ "Budgets", budgets_path ], [ controller_name.titleize, nil ] ]
      else
        # Default to Home for anything else
        [ [ "Home", root_path ], [ controller_name.titleize, nil ] ]
      end
    end
  end

  private
    def calculate_total(item, money_method, negate)
      items = item.reject { |i| i.respond_to?(:entryable) && i.entryable.transfer? }
      total = items.sum(&money_method)
      negate ? -total : total
    end
end

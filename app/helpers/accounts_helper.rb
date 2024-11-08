module AccountsHelper
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

  def summary_card(title:, &block)
    content = capture(&block)
    render "accounts/summary_card", title: title, content: content
  end

  def to_accountable_title(accountable)
    accountable.model_name.human
  end

  def accountable_text_class(accountable_type)
    class_mapping(accountable_type)[:text]
  end

  def accountable_fill_class(accountable_type)
    class_mapping(accountable_type)[:fill]
  end

  def accountable_bg_class(accountable_type)
    class_mapping(accountable_type)[:bg]
  end

  def accountable_bg_transparent_class(accountable_type)
    class_mapping(accountable_type)[:bg_transparent]
  end

  def accountable_color(accountable_type)
    class_mapping(accountable_type)[:hex]
  end

  def account_groups(period: nil)
    assets, liabilities = Current.family.accounts.active.by_group(currency: Current.family.currency, period: period || Period.last_30_days).values_at(:assets, :liabilities)
    [ assets.children.sort_by(&:name), liabilities.children.sort_by(&:name) ].flatten
  end

  private

    def class_mapping(accountable_type)
      {
        "CreditCard" => { text: "text-red-500", bg: "bg-red-500", bg_transparent: "bg-red-500/10", fill: "fill-red-500", hex: "#F13636" },
        "Loan" => { text: "text-fuchsia-500", bg: "bg-fuchsia-500", bg_transparent: "bg-fuchsia-500/10", fill: "fill-fuchsia-500", hex: "#D444F1" },
        "OtherLiability" => { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10", fill: "fill-gray-500", hex: "#737373" },
        "Depository" => { text: "text-violet-500", bg: "bg-violet-500", bg_transparent: "bg-violet-500/10", fill: "fill-violet-500", hex: "#875BF7" },
        "Investment" => { text: "text-blue-600", bg: "bg-blue-600", bg_transparent: "bg-blue-600/10", fill: "fill-blue-600", hex: "#1570EF" },
        "OtherAsset" => { text: "text-green-500", bg: "bg-green-500", bg_transparent: "bg-green-500/10", fill: "fill-green-500", hex: "#12B76A" },
        "Property" => { text: "text-cyan-500", bg: "bg-cyan-500", bg_transparent: "bg-cyan-500/10", fill: "fill-cyan-500", hex: "#06AED4" },
        "Vehicle" => { text: "text-pink-500", bg: "bg-pink-500", bg_transparent: "bg-pink-500/10", fill: "fill-pink-500", hex: "#F23E94" }
      }.fetch(accountable_type, { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10", fill: "fill-gray-500", hex: "#737373" })
    end
end

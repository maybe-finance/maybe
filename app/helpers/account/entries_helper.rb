module Account::EntriesHelper
  def permitted_entryable_partial_path(entry, relative_partial_path)
    "account/entries/entryables/#{permitted_entryable_key(entry)}/#{relative_partial_path}"
  end

  def unconfirmed_transfer?(entry)
    entry.marked_as_transfer? && entry.transfer.nil?
  end

  def transfer_entries(entries)
    transfers = entries.select { |e| e.transfer_id.present? }
    transfers.map(&:transfer).uniq
  end

  def entry_icon(entry, is_oldest: false)
    if is_oldest
      "keyboard"
    elsif entry.trend.direction.up?
      "arrow-up"
    elsif entry.trend.direction.down?
      "arrow-down"
    else
      "minus"
    end
  end

  def entry_style(entry, is_oldest: false)
    color = is_oldest ? "#D444F1" : entry.trend.color

    mixed_hex_styles(color)
  end

  def entry_name(entry)
    if entry.account_trade?
      trade     = entry.account_trade
      prefix    = trade.sell? ? "Sell " : "Buy "
      generated = prefix + "#{trade.qty.abs} shares of #{trade.security.ticker}"
      name      = entry.name || generated
      name
    else
      entry.name
    end
  end

  def entries_by_date(entries, selectable: true)
    entries.group_by(&:date).map do |date, grouped_entries|
      content = capture do
        yield grouped_entries
      end

      render partial: "account/entries/entry_group", locals: { date:, entries: grouped_entries, content:, selectable: }
    end.join.html_safe
  end

  private

    def permitted_entryable_key(entry)
      permitted_entryable_paths = %w[transaction valuation trade]
      entry.entryable_name_short.presence_in(permitted_entryable_paths)
    end
end

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

  private

    def permitted_entryable_key(entry)
      permitted_entryable_paths = %w[transaction valuation]
      entry.entryable_name_short.presence_in(permitted_entryable_paths)
    end
end

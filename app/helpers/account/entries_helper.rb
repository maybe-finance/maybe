module Account::EntriesHelper
  def permitted_entryable_key(entry)
    permitted_entryables = %w[transaction valuation]
    entry.entryable_name_short.presence_in(permitted_entryables)
  end

  def unconfirmed_transfer?(entry)
    entry.marked_as_transfer? && entry.transfer.nil?
  end

  def transfer_entries(entries)
    transfers = entries.select { |e| e.transfer_id.present? }
    transfers.map(&:transfer).uniq
  end
end

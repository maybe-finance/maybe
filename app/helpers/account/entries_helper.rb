module Account::EntriesHelper
  def permitted_entryable_key(entry)
    permitted_entryables = %w[transaction valuation]
    entry.entryable_name_short.presence_in(permitted_entryables)
  end
end

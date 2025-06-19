module EntriesHelper
  def entries_by_date(entries, totals: false)
    # Group transactions that might be transfers by their matching criteria
    # Use amount, date, and currency to identify potential transfer pairs
    transfer_groups = entries.group_by do |entry|
      # Only check for transfer-type transactions
      next nil unless entry.entryable_type == "Transaction"
      transaction = entry.entryable
      next nil unless transaction.transfer?

      # Create a grouping key based on transfer matching criteria
      # This groups transactions that are likely transfer pairs
      [
        entry.amount_money.abs, # Absolute amount
        entry.currency,
        entry.date
      ]
    end

    # For a more intuitive UX, we do not want to show the same transfer twice in the list
    # Keep the outflow side (positive amount) and reject the inflow side (negative amount)
    deduped_entries = transfer_groups.flat_map do |group_key, grouped_entries|
      if group_key.nil? || grouped_entries.size == 1
        # Not a transfer or only one side found, keep all entries
        grouped_entries
      else
        # Multiple entries with same amount/date/currency - likely a transfer pair
        # Keep the outflow side (positive amount) and reject inflow side (negative amount)
        grouped_entries.reject do |entry|
          entry.entryable_type == "Transaction" &&
          entry.entryable.transfer? &&
          entry.amount.negative? # This is the inflow side
        end
      end
    end

    deduped_entries.group_by(&:date).sort.reverse_each.map do |date, grouped_entries|
      content = capture do
        yield grouped_entries
      end

      next if content.blank?

      render partial: "entries/entry_group", locals: { date:, entries: grouped_entries, content:, totals: }
    end.compact.join.html_safe
  end

  def entry_name_detailed(entry)
    [
      entry.date,
      format_money(entry.amount_money),
      entry.account.name,
      entry.name
    ].join(" • ")
  end

  # Helper method to derive transfer name without Transfer association
  def transfer_name_for_transaction(transaction)
    entry = transaction.entry

    # For loan payments, use payment language
    if transaction.loan_payment?
      "Payment to #{entry.account.name}"
    # For other transfer types, use transfer language
    else
      # Default transfer name based on the account
      "Transfer involving #{entry.account.name}"
    end
  end
end

module Family::AutoTransferMatchable
  def transfer_match_candidates
    Entry.select([
      "inflow_candidates.entryable_id as inflow_transaction_id",
      "outflow_candidates.entryable_id as outflow_transaction_id",
      "ABS(inflow_candidates.date - outflow_candidates.date) as date_diff"
    ]).from("entries inflow_candidates")
      .joins("
        JOIN entries outflow_candidates ON (
          inflow_candidates.amount < 0 AND
          outflow_candidates.amount > 0 AND
          inflow_candidates.amount = -outflow_candidates.amount AND
          inflow_candidates.currency = outflow_candidates.currency AND
          inflow_candidates.account_id <> outflow_candidates.account_id AND
          inflow_candidates.date BETWEEN outflow_candidates.date - 4 AND outflow_candidates.date + 4
        )
      ").joins("
        LEFT JOIN transfers existing_transfers ON (
          existing_transfers.inflow_transaction_id = inflow_candidates.entryable_id OR
          existing_transfers.outflow_transaction_id = outflow_candidates.entryable_id
        )
      ")
      .joins("LEFT JOIN rejected_transfers ON (
        rejected_transfers.inflow_transaction_id = inflow_candidates.entryable_id AND
        rejected_transfers.outflow_transaction_id = outflow_candidates.entryable_id
      )")
      .joins("JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_candidates.account_id")
      .joins("JOIN accounts outflow_accounts ON outflow_accounts.id = outflow_candidates.account_id")
      .where("inflow_accounts.family_id = ? AND outflow_accounts.family_id = ?", self.id, self.id)
      .where("inflow_accounts.is_active = true")
      .where("outflow_accounts.is_active = true")
      .where("inflow_candidates.entryable_type = 'Transaction' AND outflow_candidates.entryable_type = 'Transaction'")
      .where(existing_transfers: { id: nil })
      .order("date_diff ASC") # Closest matches first
  end

  def auto_match_transfers!
    # Exclude already matched transfers
    candidates_scope = transfer_match_candidates.where(rejected_transfers: { id: nil })

    # Track which transactions we've already matched to avoid duplicates
    used_transaction_ids = Set.new

    candidates = []

    Transfer.transaction do
      candidates_scope.each do |match|
        next if used_transaction_ids.include?(match.inflow_transaction_id) ||
               used_transaction_ids.include?(match.outflow_transaction_id)

        Transfer.create!(
          inflow_transaction_id: match.inflow_transaction_id,
          outflow_transaction_id: match.outflow_transaction_id,
        )

        used_transaction_ids << match.inflow_transaction_id
        used_transaction_ids << match.outflow_transaction_id
      end
    end
  end
end

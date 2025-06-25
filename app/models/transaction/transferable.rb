module Transaction::Transferable
  extend ActiveSupport::Concern

  included do
    has_one :transfer_as_inflow, class_name: "Transfer", foreign_key: "inflow_transaction_id", dependent: :destroy
    has_one :transfer_as_outflow, class_name: "Transfer", foreign_key: "outflow_transaction_id", dependent: :destroy

    # We keep track of rejected transfers to avoid auto-matching them again
    has_one :rejected_transfer_as_inflow, class_name: "RejectedTransfer", foreign_key: "inflow_transaction_id", dependent: :destroy
    has_one :rejected_transfer_as_outflow, class_name: "RejectedTransfer", foreign_key: "outflow_transaction_id", dependent: :destroy
  end

  def transfer
    transfer_as_inflow || transfer_as_outflow
  end

  def transfer_match_candidates
    candidates_scope = if self.entry.amount.negative?
      family_matches_scope.where("inflow_candidates.entryable_id = ?", self.id)
    else
      family_matches_scope.where("outflow_candidates.entryable_id = ?", self.id)
    end

    candidates_scope.map do |match|
      Transfer.new(
        inflow_transaction_id: match.inflow_transaction_id,
        outflow_transaction_id: match.outflow_transaction_id,
      )
    end
  end

  private
    def family_matches_scope
      self.entry.account.family.transfer_match_candidates
    end
end

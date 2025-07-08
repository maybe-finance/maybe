class Valuation < ApplicationRecord
  include Entryable

  enum :kind, {
    recon: "recon", # A balance reconciliation that sets the Account balance from this point forward (often defined by user)
    snapshot: "snapshot", # An "event-sourcing snapshot", which is purely for performance so less history is required to derive the balance
    opening_anchor: "opening_anchor", # Each account has a single opening anchor, which defines the opening balance on the account
    current_anchor: "current_anchor" # Each account has a single current anchor, which defines the current balance on the account
  }, validate: true

  # Each account can have at most 1 opening anchor and 1 current anchor. All valuations between these anchors should
  # be either "recon" or "snapshot". This ensures we can reliably construct the account balance history solely from Entries.
  validate :unique_anchor_per_account, if: -> { opening_anchor? || current_anchor? }
  validate :manual_accounts_cannot_have_current_anchor

  private
    def unique_anchor_per_account
      return unless entry&.account

      existing_anchor = entry.account.valuations
                             .joins(:entry)
                             .where(kind: kind)
                             .where.not(id: id)
                             .exists?

      if existing_anchor
        errors.add(:kind, "#{kind.humanize} already exists for this account")
      end
    end

    def manual_accounts_cannot_have_current_anchor
      return unless entry&.account

      if entry.account.unlinked? && current_anchor?
        errors.add(:kind, "Manual accounts cannot have a current anchor")
      end
    end
end

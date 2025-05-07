module Account::Linkable
  extend ActiveSupport::Concern

  included do
    before_destroy :restrict_linked_account_deletion

    belongs_to :plaid_account, optional: true
  end

  # A "linked" account gets transaction and balance data from a third party like Plaid
  def linked?
    plaid_account_id.present?
  end

  # An "offline" or "unlinked" account is one where the user tracks values and
  # adds transactions manually, without the help of a data provider
  def unlinked?
    !linked?
  end

  private
    def restrict_linked_account_deletion
      if linked?
        errors.add(:base, "Cannot delete a linked account")
        throw(:abort)
      end
    end
end

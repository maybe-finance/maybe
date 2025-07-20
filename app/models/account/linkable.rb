module Account::Linkable
  extend ActiveSupport::Concern

  included do
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
  alias_method :manual?, :unlinked?
end

module Accountable
  extend ActiveSupport::Concern

  ASSET_TYPES = %w[Depository Investment Crypto Property Vehicle OtherAsset]
  LIABILITY_TYPES = %w[CreditCard Loan OtherLiability]
  TYPES = ASSET_TYPES + LIABILITY_TYPES

  def self.from_type(type)
    return nil unless TYPES.include?(type)
    type.constantize
  end

  def self.by_classification
    { assets: ASSET_TYPES, liabilities: LIABILITY_TYPES }
  end

  included do
    has_one :account, as: :accountable, touch: true
  end 

  def post_sync
    broadcast_replace_to(
      account,
      target: "chart_account_#{account.id}",
      partial: "accounts/show/chart",
      locals: { account: account }
    )
  end 
end

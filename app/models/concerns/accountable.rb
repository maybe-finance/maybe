module Accountable
  extend ActiveSupport::Concern

  ASSET_TYPES = %w[ Depository Investment Crypto OtherAssetAccount PropertyAccount VehicleAccount ]
  LIABILITY_TYPES = %w[ CreditCard LoanAccount OtherLiabilityAccount ]
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
end

module Accountable
  extend ActiveSupport::Concern

  TYPES = %w[ Account::Credit Account::Depository Account::Investment Account::Loan Account::OtherAsset Account::OtherLiability Account::Property Account::Vehicle ]

  def self.from_type(type)
    return nil unless types.include?(type)
    "Account::#{type}".constantize
  end

  def self.types
    TYPES.map { |type| type.demodulize }
  end

  included do
    has_one :account, as: :accountable, touch: true
  end
end

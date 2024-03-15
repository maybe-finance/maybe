module Accountable
  extend ActiveSupport::Concern

  ASSET_TYPES = %w[ Account::Depository Account::Investment Account::OtherAsset Account::Property Account::Vehicle ]
  LIABILITY_TYPES = %w[ Account::Credit Account::Loan Account::OtherLiability ]
  TYPES = ASSET_TYPES + LIABILITY_TYPES

  def self.from_type(type)
    return nil unless types.include?(type) || TYPES.include?(type)
    "Account::#{type.demodulize}".constantize
  end

  def self.by_classification
    { assets: ASSET_TYPES, liabilities: LIABILITY_TYPES }
  end

  def self.types(classification = nil)
    types = classification ? (classification.to_sym == :asset ? ASSET_TYPES : LIABILITY_TYPES) : TYPES
    types.map { |type| type.demodulize }
  end

  def self.classification(type)
    ASSET_TYPES.include?(type) ? :asset : :liability
  end

  included do
    has_one :account, as: :accountable, touch: true
  end
end

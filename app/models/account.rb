class Account < ApplicationRecord
  VALID_ACCOUNT_TYPES = %w[Investment Depository Credit Loan Property Vehicle OtherAsset OtherLiability].freeze
  
  belongs_to :family

  scope :depository, -> { where(type: 'Depository') }
end

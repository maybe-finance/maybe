class Account < ApplicationRecord
  belongs_to :family

  scope :depository, -> { where(type: 'Depository') }
  VALID_ACCOUNT_TYPES = %w[Investment Depository Credit Loan Property Vehicle OtherAsset OtherLiability].freeze
end

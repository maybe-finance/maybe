class Account < ApplicationRecord
  VALID_ACCOUNT_TYPES = %w[Investment Depository Credit Loan Property Vehicle OtherAsset OtherLiability].freeze

  belongs_to :family

  delegated_type :accountable, types: %w[ Credit Depository Investment Loan OtherAsset OtherLiability Property Vehicle], dependant: :destroy

  scope :depository, -> { where(type: "Depository") }
end

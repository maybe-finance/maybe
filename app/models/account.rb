class Account < ApplicationRecord
  belongs_to :family

  VALID_ACCOUNT_TYPES = %w[Investment Depository Credit Loan Property Vehicle OtherAsset OtherLiability].freeze
end

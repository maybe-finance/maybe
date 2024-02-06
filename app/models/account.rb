class Account < ApplicationRecord
  belongs_to :family

  delegated_type :accountable, types: %w[ Account::Credit Account::Depository Account::Investment Account::Loan Account::OtherAsset Account::OtherLiability Account::Property Account::Vehicle], dependent: :destroy

  delegate :type_name, to: :accountable

  monetize :balance_cents
end

class Account < ApplicationRecord
  belongs_to :family

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable

  monetize :balance_cents
end

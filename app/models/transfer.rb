class Transfer < ApplicationRecord
  has_many :transactions, dependent: :nullify
end

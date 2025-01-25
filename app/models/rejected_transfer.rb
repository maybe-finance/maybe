class RejectedTransfer < ApplicationRecord
  belongs_to :inflow_transaction, class_name: "Account::Transaction"
  belongs_to :outflow_transaction, class_name: "Account::Transaction"
end

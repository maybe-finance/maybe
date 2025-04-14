class RejectedTransfer < ApplicationRecord
  belongs_to :inflow_transaction, class_name: "Transaction"
  belongs_to :outflow_transaction, class_name: "Transaction"
end

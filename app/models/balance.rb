class Balance < ApplicationRecord
  belongs_to :account
  belongs_to :security, optional: true
  belongs_to :family
end

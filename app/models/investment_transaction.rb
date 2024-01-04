class InvestmentTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :security
end

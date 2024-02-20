# STI model to represent a point-in-time "valuation" of an account's value
# Types include: Appraisal, Adjustment
class Valuation < ApplicationRecord
  belongs_to :account
end

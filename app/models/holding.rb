class Holding < ApplicationRecord
  belongs_to :user
  belongs_to :security
  belongs_to :portfolio
end

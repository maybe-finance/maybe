class Metric < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :family
end

class Rule::Action < ApplicationRecord
  belongs_to :rule

  validates :action_type, presence: true
end

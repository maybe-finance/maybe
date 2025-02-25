class Rule::Trigger < ApplicationRecord
  self.table_name = "rule_triggers"

  belongs_to :rule

  validates :trigger_type, presence: true
end

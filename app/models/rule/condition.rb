class Rule::Condition < ApplicationRecord
  OPERATORS = [ "and", "or", "gt", "lt", "eq" ]
  TYPES = [ "match_merchant", "compare_amount", "compound" ]

  belongs_to :rule, optional: true
  belongs_to :parent, class_name: "Rule::Condition", optional: true
  has_many :conditions, class_name: "Rule::Condition", foreign_key: :parent_id, dependent: :destroy

  validates :operator, inclusion: { in: OPERATORS }, allow_nil: true
  validates :condition_type, presence: true, inclusion: { in: TYPES }
end

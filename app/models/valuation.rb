class Valuation < ApplicationRecord
  include Entryable

  enum :kind, {
    reconciliation: "reconciliation",
    opening_anchor: "opening_anchor",
    current_anchor: "current_anchor"
  }, validate: true, default: "reconciliation"
end

class Valuation < ApplicationRecord
  include Entryable

  enum :kind, {
    reconciliation: "reconciliation",
    opening_anchor: "opening_anchor",
    current_anchor: "current_anchor"
  }, validate: true, default: "reconciliation"

  class << self
    def build_reconciliation_name(accountable_type)
      Valuation::Name.new("reconciliation", accountable_type).to_s
    end

    def build_opening_anchor_name(accountable_type)
      Valuation::Name.new("opening_anchor", accountable_type).to_s
    end

    def build_current_anchor_name(accountable_type)
      Valuation::Name.new("current_anchor", accountable_type).to_s
    end
  end
end

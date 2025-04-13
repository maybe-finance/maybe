class DataEnrichment < ApplicationRecord
  belongs_to :enrichable, polymorphic: true

  enum :source, { rule: "rule", plaid: "plaid", synth: "synth" }
end

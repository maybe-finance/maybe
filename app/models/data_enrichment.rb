class DataEnrichment < ApplicationRecord
  belongs_to :enrichable, polymorphic: true
end

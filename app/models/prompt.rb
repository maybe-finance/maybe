class Prompt < ApplicationRecord
  def self.unique_categories
    pluck(:categories).flatten.uniq
  end
end

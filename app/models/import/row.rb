class Import::Row < ApplicationRecord
  belongs_to :import

  scope :ordered, -> { order(:id) }

  def tags_list
    if tags.blank?
      [ "" ]
    else
      tags.split("|").map(&:strip)
    end
  end

  def sync_mappings
    Import::CategoryMapping.sync(import)
    Import::TagMapping.sync(import)
    Import::AccountMapping.sync(import)
    Import::AccountTypeMapping.sync(import)
  end
end

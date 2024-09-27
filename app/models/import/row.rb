class Import::Row < ApplicationRecord
  EMPTY_KEY = "[empty]".freeze

  belongs_to :import

  scope :ordered, -> { order(created_at: :desc) }

  def tags_list
    tags.split("|").map(&:strip)
  end

  def sync_mappings
    Import::CategoryMapping.sync_rows([ self ])
    Import::TagMapping.sync_rows([ self ])
    Import::AccountMapping.sync_rows([ self ])
    Import::AccountTypeMapping.sync_rows([ self ])
  end
end

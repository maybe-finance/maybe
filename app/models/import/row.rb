class Import::Row < ApplicationRecord
  belongs_to :import

  validates :date, presence: true, if: -> { import.type in ["TransactionImport", "TradeImport", "MintImport"] }
  validates :amount, numericality: true
  validate :date_matches_user_format

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

  private
    def date_matches_user_format
      return if date.blank?

      parsed_date = Date.strptime(date, import.date_format) rescue nil
      if parsed_date.nil?
        errors.add(:date, "must exactly match the format: #{import.date_format}")
      end
    end
end

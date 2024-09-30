class Import::Row < ApplicationRecord
  belongs_to :import

  validates :amount, numericality: true, allow_blank: true
  validates :currency, presence: true

  validate :date_matches_user_format
  validate :required_columns
  validate :currency_is_valid

  scope :ordered, -> { order(:id) }

  def tags_list
    if tags.blank?
      [ "" ]
    else
      tags.split("|").map(&:strip)
    end
  end

  def date_iso
    Date.strptime(date, import.date_format).iso8601
  end

  def signed_amount
    if import.type == "TradeImport"
      price.to_d * apply_signage_convention(qty.to_d)
    else
      apply_signage_convention(amount.to_d)
    end
  end

  def sync_mappings
    Import::CategoryMapping.sync(import) if import.column_keys.include?(:category)
    Import::TagMapping.sync(import) if import.column_keys.include?(:tags)
    Import::AccountMapping.sync(import) if import.column_keys.include?(:account)
    Import::AccountTypeMapping.sync(import) if import.column_keys.include?(:entity_type)
  end

  private
    def apply_signage_convention(value)
      value * (import.signage_convention == "inflows_positive" ? 1 : -1)
    end

    def required_columns
      import.required_column_keys.each do |required_key|
        errors.add(required_key, "is required") if self[required_key].blank?
      end
    end

    def date_matches_user_format
      return if date.blank?

      parsed_date = Date.strptime(date, import.date_format) rescue nil

      if parsed_date.nil?
        errors.add(:date, "must exactly match the format: #{import.date_format}")
      end
    end

    def currency_is_valid
      return true if currency.blank?

      begin
        Money::Currency.new(currency)
      rescue Money::Currency::UnknownCurrencyError
        errors.add(:currency, "is not a valid currency code")
      end
    end
end

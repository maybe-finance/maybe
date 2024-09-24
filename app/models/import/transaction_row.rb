class Import::TransactionRow < Import::Row
  validates :date, :amount, presence: true
  validates :amount, numericality: { other_than: 0 }
  validate :date_matches_user_format

  private
    def date_matches_user_format
      return if date.blank?

      parsed_date = Date.strptime(date, import.date_format) rescue nil
      if parsed_date.nil? || parsed_date.strftime(import.date_format) != date
        errors.add(:date, "must exactly match the format: #{import.date_format}")
      end
    end
end

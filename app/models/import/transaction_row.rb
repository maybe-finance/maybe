class Import::TransactionRow < Import::Row
  validates :date, :amount, presence: true
  validates :amount, numericality: true
  validate :date_matches_user_format

  private
    def date_matches_user_format
      return if date.blank?

      parsed_date = Date.strptime(date, import.date_format) rescue nil
      if parsed_date.nil?
        errors.add(:date, "must exactly match the format: #{import.date_format}")
      end
    end
end

class Account::MetricsCalculator
  def initialize(account)
    @account = account
  end

  def calculate
    calculate_spending
  end

  private

    def calculate_spending
      entries = @account.entries
                      .account_transactions
                      .without_transfers
                      .where(amount: ..0)
                      .where("date >= ?", 30.days.ago)

      daily_spending = entries.group("DATE(date)").sum(:amount).transform_values(&:abs)

      daily_spending.each do |date, amount|
        @account.metrics.find_or_initialize_by(
          family: @account.family,
          kind: "spending",
          date: date
        ).update!(value: amount)
      end
    end
end

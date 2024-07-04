class Account::Balance < ApplicationRecord
  include Monetizable, Syncable

  belongs_to :account
  validates :account, :date, :balance, presence: true
  monetize :balance
  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
  scope :in_currency, ->(currency) { where(currency: currency) }
  scope :chronological, -> { order(:date) }
  scope :reverse_chronological, -> { order(date: :desc) }

  class << self
    def sync(account, start_date = nil)
      calculator = Account::Balance::Calculator.new(account, { calc_start_date: start_date })

      save_balances(calculator.daily_balances)
      purge_stale_balances(account)
      convert_balances_to_family_currency(account)
      build_response(calculator)
    end

    private

      def build_response(calculator)
        error = calculator.errors.first
        warnings = calculator.warnings

        Syncable::Response.new(success?: error.nil?, error: error, warnings: warnings)
      end

      def save_balances(balances)
        upsert_all(balances, unique_by: :index_account_balances_on_account_id_date_currency_unique)
      end

      def purge_stale_balances(account)
        where("date < ?", account.effective_start_date).delete_all
      end

      def convert_balances_to_family_currency(account)
        rates = ExchangeRate.find_rates(
          from: account.currency,
          to: account.family.currency,
          start_date: calc_start_date
        ).to_a

        # Abort conversion if some required rates are missing
        if rates.length != balances.length
          @errors << :sync_message_missing_rates
          return []
        end

        balances.map.with_index do |balance, index|
          converted_balance = balance[:balance] * rates[index].rate
          { date: balance[:date], balance: converted_balance, currency: account.family.currency, updated_at: Time.current }
        end
      end
  end
end

class Account::Balance < ApplicationRecord
    include Monetizable

    belongs_to :account
    validates :account, :date, :balance, presence: true
    monetize :balance
    scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
    scope :in_currency, ->(currency) { where(currency: currency) }
    scope :chronological, -> { order(:date) }
    scope :reverse_chronological, -> { order(date: :desc) }

    class << self
      def sync(account, start_date: nil)
        calculator = Account::Balance::Calculator.new(account, { calc_start_date: start_date })

        upsert_all(calculator.daily_balances, unique_by: :index_account_balances_on_account_id_date_currency_unique)
        where("date < ?", effective_start_date).delete_all
      end
    end
end

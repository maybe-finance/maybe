class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = {
    "brokerage" => { short: "Brokerage", long: "Brokerage" },
    "pension" => { short: "Pension", long: "Pension" },
    "retirement" => { short: "Retirement", long: "Retirement" },
    "401k" => { short: "401(k)", long: "401(k)" },
    "roth_401k" => { short: "Roth 401(k)", long: "Roth 401(k)" },
    "529_plan" => { short: "529 Plan", long: "529 Plan" },
    "hsa" => { short: "HSA", long: "Health Savings Account" },
    "mutual_fund" => { short: "Mutual Fund", long: "Mutual Fund" },
    "ira" => { short: "IRA", long: "Traditional IRA" },
    "roth_ira" => { short: "Roth IRA", long: "Roth IRA" },
    "angel" => { short: "Angel", long: "Angel" }
  }.freeze

  class << self
    def color
      "#1570EF"
    end

    def classification
      "asset"
    end

    def icon
      "line-chart"
    end
  end

  def holdings_value_for_date(date)
    # Find the most recent holding for each security on or before the given date
    # Using a subquery to get the max date for each security
    account.holdings
      .where(currency: account.currency)
      .where("date <= ?", date)
      .where("(security_id, date) IN (
        SELECT security_id, MAX(date) as max_date
        FROM holdings
        WHERE account_id = ? AND date <= ?
        GROUP BY security_id
      )", account.id, date)
      .sum(:amount)
  end
end

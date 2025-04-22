class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = {
    "brokerage" => { short: "Brokerage", long: "Brokerage" },
    "pension" => { short: "Pension", long: "Pension" },
    "retirement" => { short: "Retirement", long: "Retirement" },
    "401k" => { short: "401(k)", long: "401(k)" },
    "traditional_401k" => { short: "Traditional 401(k)", long: "Traditional 401(k)" },
    "roth_401k" => { short: "Roth 401(k)", long: "Roth 401(k)" },
    "529_plan" => { short: "529 Plan", long: "529 Plan" },
    "hsa" => { short: "HSA", long: "Health Savings Account" },
    "mutual_fund" => { short: "Mutual Fund", long: "Mutual Fund" },
    "traditional_ira" => { short: "Traditional IRA", long: "Traditional IRA" },
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
end

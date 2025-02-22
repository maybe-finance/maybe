class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Brokerage", "brokerage" ],
    [ "Pension", "pension" ],
    [ "Retirement", "retirement" ],
    [ "401(k)", "401k" ],
    [ "Traditional 401(k)", "traditional_401k" ],
    [ "Roth 401(k)", "roth_401k" ],
    [ "529 Plan", "529_plan" ],
    [ "Health Savings Account", "hsa" ],
    [ "Mutual Fund", "mutual_fund" ],
    [ "Traditional IRA", "traditional_ira" ],
    [ "Roth IRA", "roth_ira" ],
    [ "Angel", "angel" ]
  ].freeze

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

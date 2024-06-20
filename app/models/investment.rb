class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Brokerage", "brokerage" ],
    [ "Pension", "pension" ],
    [ "Retirement", "retirement" ],
    [ "401(k)", "401k" ],
    [ "529 plan", "529_plan" ],
    [ "Health Savings Account", "hsa" ],
    [ "Mutual Fund", "mutual_fund" ],
    [ "Roth IRA", "roth_ira" ],
    [ "Roth 401k", "roth_401k" ],
    [ "Angel", "angel" ]
  ].freeze
end

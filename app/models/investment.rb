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

  def color
    "#1570EF"
  end

  def icon
    "line-chart"
  end

  def post_sync
    broadcast_replace_to(
      account,
      target: "chart_account_#{account.id}",
      partial: account.plaid_account_id.present? ? "investments/chart" : "accounts/show/chart",
      locals: { account: account }
    )
  end
end

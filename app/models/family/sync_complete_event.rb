class Family::SyncCompleteEvent
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def broadcast
    family.broadcast_replace(
      target: "balance-sheet",
      partial: "pages/dashboard/balance_sheet",
      locals: { balance_sheet: family.balance_sheet }
    )

    family.broadcast_replace(
      target: "net-worth-chart",
      partial: "pages/dashboard/net_worth_chart",
      locals: { balance_sheet: family.balance_sheet, period: Period.last_30_days }
    )
  end
end

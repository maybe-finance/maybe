class SyncCompleteEvent
  attr_reader :family, :accounts

  def initialize(family, accounts: [])
    @family = family
    @accounts = accounts
  end

  def broadcast
    account_groups = family.balance_sheet.account_groups.select do |group|
      group.accounts.any? { |a| accounts.include?(a) }
    end

    account_groups.each do |account_group|
      [ nil, "asset", "liability" ].each do |classification|
        id = classification ? "#{classification}_#{account_group.id}" : account_group.id
        family.broadcast_replace(
          target: id,
          partial: "accounts/accountable_group",
          locals: { account_group: account_group, open: true }
        )
      end
    end

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

class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts

  def net_worth
    accounts.sum("CASE WHEN classification = 'asset' THEN balance ELSE -balance END")
  end

  def assets
    accounts.where(classification: "asset").sum(:balance)
  end

  def liabilities
    accounts.where(classification: "liability").sum(:balance)
  end

  def balances_by_type(period = nil)
    balances = balance_by_type_query(period).to_a

    grouped = { "asset" => [], "liability" => [] }

    balances.each do |row|
      data = {
        accountable_type: row.accountable_type,
        current: row.curr_balance,
        previous: row.prev_balance,
        trend: Trend.new(current: row.curr_balance, previous: row.prev_balance, type: row.classification)
      }

      grouped[row.classification] << data
    end

    grouped
  end

  def net_worth_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance ELSE -account_balances.balance END) AS balance, 'USD' as currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "asset" }
    )
  end

  def asset_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(account_balances.balance) AS balance, 'asset' AS classification, 'USD' AS currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")
      .where(classification: "asset")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "asset" }
    )
  end

  def liability_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(account_balances.balance) AS balance, 'liability' AS classification, 'USD' AS currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")
      .where(classification: "liability")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "liability" }
    )
  end

  private

    #   Sample output:
    # | accountable_type    | classification | prev_balance | curr_balance |
    # |---------------------|----------------|--------------|--------------|
    # | Account::Credit     | liability      | 500          | 1000         |
    # | Account::Depository | asset          | 22000        | 25000        |
    def balance_by_type_query(period = nil)
      ranked_balances_cte = accounts.joins(:balances)
        .select("
          account_balances.account_id,
          account_balances.balance,
          account_balances.date,
          ROW_NUMBER() OVER (PARTITION BY account_balances.account_id ORDER BY date ASC) AS rn_asc,
          ROW_NUMBER() OVER (PARTITION BY account_balances.account_id ORDER BY date DESC) AS rn_desc
        ")

      if period && period.date_range
        ranked_balances_cte = ranked_balances_cte.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
      end

      AccountBalance.with(
        ranked_balances: ranked_balances_cte
      )
        .from("ranked_balances AS rb")
        .joins("JOIN accounts a ON a.id = rb.account_id")
        .select("
          a.accountable_type,
          a.classification,
          SUM(CASE WHEN rb.rn_asc = 1 THEN rb.balance ELSE 0 END) AS prev_balance,
          SUM(CASE WHEN rb.rn_desc = 1 THEN rb.balance ELSE 0 END) AS curr_balance
        ")
        .where("rb.rn_asc = 1 OR rb.rn_desc = 1")
        .group("a.accountable_type, a.classification")
        .order("curr_balance DESC")
    end
end

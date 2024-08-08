module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end

  def accountable_text_class(accountable_type)
    class_mapping(accountable_type)[:text]
  end

  def accountable_fill_class(accountable_type)
    class_mapping(accountable_type)[:fill]
  end

  def accountable_bg_class(accountable_type)
    class_mapping(accountable_type)[:bg]
  end

  def accountable_bg_transparent_class(accountable_type)
    class_mapping(accountable_type)[:bg_transparent]
  end

  def accountable_color(accountable_type)
    class_mapping(accountable_type)[:hex]
  end

  def account_tabs(account)
    holdings_tab = { key: "holdings", label: t("accounts.show.holdings"), path: account_path(account, tab: "holdings"), content_path: account_holdings_path(account) }
    cash_tab = { key: "cash", label: t("accounts.show.cash"), path: account_path(account, tab: "cash"), content_path: account_cashes_path(account) }
    value_tab        = { key: "valuations", label: t("accounts.show.value"), path: account_path(account, tab: "valuations"), content_path: account_valuations_path(account) }
    transactions_tab = { key: "transactions", label: t("accounts.show.transactions"), path: account_path(account, tab: "transactions"), content_path: account_transactions_path(account) }
    trades_tab       = { key: "trades", label: t("accounts.show.trades"), path: account_path(account, tab: "trades"), content_path: account_trades_path(account) }

    return [ holdings_tab, cash_tab, trades_tab ] if account.investment?

    [ value_tab, transactions_tab ]
  end

  def selected_account_tab(account)
    available_tabs = account_tabs(account)

    tab = available_tabs.find { |tab| tab[:key] == params[:tab] }

    tab || available_tabs.first
  end

  private

    def class_mapping(accountable_type)
      {
        "CreditCard" => { text: "text-red-500", bg: "bg-red-500", bg_transparent: "bg-red-500/10", fill: "fill-red-500", hex: "#F13636" },
        "Loan" => { text: "text-fuchsia-500", bg: "bg-fuchsia-500", bg_transparent: "bg-fuchsia-500/10", fill: "fill-fuchsia-500", hex: "#D444F1" },
        "OtherLiability" => { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10", fill: "fill-gray-500", hex: "#737373" },
        "Depository" => { text: "text-violet-500", bg: "bg-violet-500", bg_transparent: "bg-violet-500/10", fill: "fill-violet-500", hex: "#875BF7" },
        "Investment" => { text: "text-blue-600", bg: "bg-blue-600", bg_transparent: "bg-blue-600/10", fill: "fill-blue-600", hex: "#1570EF" },
        "OtherAsset" => { text: "text-green-500", bg: "bg-green-500", bg_transparent: "bg-green-500/10", fill: "fill-green-500", hex: "#12B76A" },
        "Property" => { text: "text-cyan-500", bg: "bg-cyan-500", bg_transparent: "bg-cyan-500/10", fill: "fill-cyan-500", hex: "#06AED4" },
        "Vehicle" => { text: "text-pink-500", bg: "bg-pink-500", bg_transparent: "bg-pink-500/10", fill: "fill-pink-500", hex: "#F23E94" }
      }.fetch(accountable_type, { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10", fill: "fill-gray-500", hex: "#737373" })
    end
end

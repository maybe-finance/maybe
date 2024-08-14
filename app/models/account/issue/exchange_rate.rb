class Account::Issue::ExchangeRate < Account::Issue
  def message
    I18n.t("account.issues.exchange_rate.message")
  end
end

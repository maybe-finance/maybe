class Account::Issue::Unknown < Account::Issue
  def message
    I18n.t("account.issues.unknown.message")
  end
end

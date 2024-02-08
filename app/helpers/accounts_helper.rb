module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end

  def humanized_account
    account_type.model_name.human
  end

  def account_type
    type = params[:type]

    Account unless type.present? && Account.accountable_types.include?(type)

    "Account::#{type}".constantize
  end
end

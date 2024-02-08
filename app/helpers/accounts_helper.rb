module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end

  def humanized_account
    account_type.model_name.human
  end

  def account_type
    case params[:type]
    when "Credit"
      Account::Credit
    when "Depository"
      Account::Depository
    when "Investment"
      Account::Investment
    when "Loan"
      Account::Loan
    when "OtherAsset"
      Account::OtherAsset
    when "OtherLiability"
      Account::OtherLiability
    when "Property"
      Account::Property
    when "Vehicle"
      Account::Vehicle
    else
      Account
    end
  end
end

module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end
  def find_model_class(type)
    case type
    when "Credit"
      Account::Credit
    when "Depository"
      Account::Depository
    when "Investment"
      Account::Investment
    when "Property"
      Account::Property
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
      nil
    end
  end
end

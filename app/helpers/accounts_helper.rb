module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end
end

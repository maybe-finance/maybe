module AccountsHelper
  def to_accountable_title(accountable)
    accountable.class.name.demodulize.titleize
  end
end

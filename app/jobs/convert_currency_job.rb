class ConvertCurrencyJob < ApplicationJob
  queue_as :default

  def perform(family)
    family = Family.find(family.id)

    # Convert all account balances to new currency
    family.accounts.each do |account|
      if account.currency == family.currency
        account.converted_balance = account.balance
        account.converted_currency = account.currency
      else
        account.converted_balance = ExchangeRate.convert(account.currency, family.currency, account.balance)
        account.converted_currency = family.currency
      end
      account.save!
    end
  end
end

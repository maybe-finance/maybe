class ConvertCurrencyJob < ApplicationJob
  queue_as :default

  def perform(family)
    family = Family.find(family.id)

    # Convert all account balances to new currency
    family.accounts.each do |account|
      if account.original_currency == family.currency
        account.converted_balance = account.original_balance
        account.converted_currency = account.original_currency
      else
        account.converted_balance = ExchangeRate.convert(account.original_currency, family.currency, account.original_balance)
        account.converted_currency = family.currency
      end
      account.save!
    end
  end
end

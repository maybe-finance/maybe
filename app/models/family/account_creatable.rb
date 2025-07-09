module Family::AccountCreatable
  extend ActiveSupport::Concern

  def create_property_account!(name:, current_value:, purchase_price: nil, purchase_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_value,
      cash_balance: 0,
      accountable_type: Property,
      opening_balance: purchase_price,
      opening_date: purchase_date,
      currency: currency
    )
  end

  def create_vehicle_account!(name:, current_value:, purchase_price: nil, purchase_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_value,
      cash_balance: 0,
      accountable_type: Vehicle,
      opening_balance: purchase_price,
      opening_date: purchase_date,
      currency: currency
    )
  end

  def create_depository_account!(name:, current_balance:, opening_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_balance,
      cash_balance: current_balance,
      accountable_type: Depository,
      opening_date: opening_date,
      currency: currency
    )
  end

  # Investment account values are built up by adding holdings / trades, not by initializing a "balance"
  def create_investment_account!(name:, currency: nil)
    create_manual_account!(
      name: name,
      balance: 0,
      cash_balance: 0,
      accountable_type: Investment,
      opening_balance: 0,  # Investment accounts start empty
      opening_cash_balance: 0,
      currency: currency
    )
  end

  def create_other_asset_account!(name:, current_value:, purchase_price: nil, purchase_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_value,
      cash_balance: 0,
      accountable_type: OtherAsset,
      opening_balance: purchase_price,
      opening_date: purchase_date,
      currency: currency
    )
  end

  def create_other_liability_account!(name:, current_debt:, original_debt: nil, origination_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_debt,
      cash_balance: 0,
      accountable_type: OtherLiability,
      opening_balance: original_debt,
      opening_date: origination_date,
      currency: currency
    )
  end

  # For now, crypto accounts are very simple; we just track overall value
  def create_crypto_account!(name:, current_value:, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_value,
      cash_balance: current_value,
      accountable_type: Crypto,
      opening_balance: current_value,
      opening_cash_balance: current_value,
      currency: currency
    )
  end

  def create_credit_card_account!(name:, current_debt:, opening_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_debt,
      cash_balance: 0,
      accountable_type: CreditCard,
      opening_balance: 0,  # Credit cards typically start with no debt
      opening_date: opening_date,
      currency: currency
    )
  end

  def create_loan_account!(name:, current_principal:, original_principal: nil, origination_date: nil, currency: nil)
    create_manual_account!(
      name: name,
      balance: current_principal,
      cash_balance: 0,
      accountable_type: Loan,
      opening_balance: original_principal,
      opening_date: origination_date,
      currency: currency
    )
  end

  def link_depository_account
    # TODO
  end

  def link_investment_account
    # TODO
  end

  def link_credit_card_account
    # TODO
  end

  def link_loan_account
    # TODO
  end

  private

  def create_manual_account!(name:, balance:, cash_balance:, accountable_type:, opening_balance: nil, opening_cash_balance: nil, opening_date: nil, currency: nil)
    Family.transaction do
      account = accounts.create!(
        name: name,
        balance: balance,
        cash_balance: cash_balance,
        currency: currency.presence || self.currency,
        accountable: accountable_type.new
      )

      account.set_or_update_opening_balance!(
        balance: opening_balance || balance,
        cash_balance: opening_cash_balance || cash_balance,
        date: opening_date
      )

      account
    end
  end
end

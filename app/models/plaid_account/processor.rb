class PlaidAccount::Processor
  attr_reader :plaid_account

  UnknownAccountTypeError = Class.new(StandardError)

  # Plaid Account Types -> Accountable Types
  TYPE_MAPPING = {
    "depository" => Depository,
    "credit" => CreditCard,
    "loan" => Loan,
    "investment" => Investment,
    "other" => OtherAsset
  }

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    PlaidAccount.transaction do
      account = family.accounts.find_or_initialize_by(
        plaid_account_id: plaid_account.id
      )

      # Name is the only attribute a user can override for Plaid accounts
      account.enrich_attribute(
        :name,
        plaid_account.name,
        source: "plaid"
      )

      account.assign_attributes(
        accountable: accountable,
        balance: balance,
        currency: plaid_account.currency,
        cash_balance: cash_balance
      )

      account.save!
    end

    PlaidAccount::TransactionsProcessor.new(plaid_account).process
    PlaidAccount::InvestmentsProcessor.new(plaid_account).process
    PlaidAccount::LiabilitiesProcessor.new(plaid_account).process
  end

  private
    def family
      plaid_account.plaid_item.family
    end

    def accountable
      accountable_class = TYPE_MAPPING[plaid_account.plaid_type]

      raise UnknownAccountTypeError, "Unknown account type: #{plaid_account.plaid_type}" unless accountable_class

      accountable_class.new
    end

    def balance
      case plaid_account.plaid_type
      when "investment"
        investment_balance_processor.balance
      else
        plaid_account.current_balance || plaid_account.available_balance
      end
    end

    def cash_balance
      case plaid_account.plaid_type
      when "investment"
        investment_balance_processor.cash_balance
      else
        plaid_account.available_balance || 0
      end
    end

    def investment_balance_processor
      PlaidAccount::InvestmentBalanceProcessor.new(plaid_account)
    end
end

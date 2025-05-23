class PlaidAccount::Processor
  include PlaidAccount::TypeMappable

  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  # Each step represents a different Plaid API endpoint / "product"
  #
  # Processing the account is the first step and if it fails, we halt the entire processor
  # Each subsequent step can fail independently, but we continue processing the rest of the steps
  def process
    process_account!
    process_transactions
    process_investments
    process_liabilities
  end

  private
    def family
      plaid_account.plaid_item.family
    end

    # Shared securities reader and resolver
    def security_resolver
      @security_resolver ||= PlaidAccount::Investments::SecurityResolver.new(plaid_account)
    end

    def process_account!
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
          accountable: map_accountable(plaid_account.plaid_type),
          subtype: map_subtype(plaid_account.plaid_type, plaid_account.plaid_subtype),
          balance: balance,
          currency: plaid_account.currency,
          cash_balance: cash_balance
        )

        account.save!
      end
    end

    def process_transactions
      PlaidAccount::Transactions::Processor.new(plaid_account).process
    rescue => e
      report_exception(e)
    end

    def process_investments
      PlaidAccount::Investments::TransactionsProcessor.new(plaid_account, security_resolver: security_resolver).process
      PlaidAccount::Investments::HoldingsProcessor.new(plaid_account, security_resolver: security_resolver).process
      report_exception(e)
    end

    def process_liabilities
      case [ plaid_account.plaid_type, plaid_account.plaid_subtype ]
      when [ "credit", "credit card" ]
        PlaidAccount::CreditLiabilityProcessor.new(plaid_account).process
      when [ "loan", "mortgage" ]
        PlaidAccount::MortgageLiabilityProcessor.new(plaid_account).process
      when [ "loan", "student" ]
        PlaidAccount::StudentLoanLiabilityProcessor.new(plaid_account).process
      end
    rescue => e
      report_exception(e)
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
      PlaidAccount::Investments::BalanceProcessor.new(plaid_account, security_resolver: security_resolver)
    end

    def report_exception(error)
      Sentry.capture_exception(error) do |scope|
        scope.set_tags(plaid_account_id: plaid_account.id)
      end
    end
end

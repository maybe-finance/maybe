module PlaidAccount::TypeMappable
  extend ActiveSupport::Concern

  UnknownAccountTypeError = Class.new(StandardError)

  def map_accountable(plaid_type)
    accountable_class = TYPE_MAPPING.dig(
      plaid_type.to_sym,
      :accountable
    )

    unless accountable_class
      raise UnknownAccountTypeError, "Unknown account type: #{plaid_type}"
    end

    accountable_class.new
  end

  def map_subtype(plaid_type, plaid_subtype)
    TYPE_MAPPING.dig(
      plaid_type.to_sym,
      :subtype_mapping,
      plaid_subtype
    ) || "other"
  end

  # Plaid Account Types -> Accountable Types
  # https://plaid.com/docs/api/accounts/#account-type-schema
  TYPE_MAPPING = {
    depository: {
      accountable: Depository,
      subtype_mapping: {
        "checking" => "checking",
        "savings" => "savings",
        "hsa" => "hsa",
        "cd" => "cd",
        "money market" => "money_market"
      }
    },
    credit: {
      accountable: CreditCard,
      subtype_mapping: {
        "credit card" => "credit_card"
      }
    },
    loan: {
      accountable: Loan,
      subtype_mapping: {
        "mortgage" => "mortgage",
        "student" => "student",
        "auto" => "auto",
        "business" => "business",
        "home equity" => "home_equity",
        "line of credit" => "line_of_credit"
      }
    },
    investment: {
      accountable: Investment,
      subtype_mapping: {
        "brokerage" => "brokerage",
        "pension" => "pension",
        "retirement" => "retirement",
        "401k" => "401k",
        "roth 401k" => "roth_401k",
        "529" => "529_plan",
        "hsa" => "hsa",
        "mutual fund" => "mutual_fund",
        "roth" => "roth_ira",
        "ira" => "ira"
      }
    },
    other: {
      accountable: OtherAsset,
      subtype_mapping: {}
    }
  }
end

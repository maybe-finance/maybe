# While typically a view concern, we store the `name` in the DB as a denormalized value to keep our search classes simpler.
# This is a simple class to handle the logic for generating the name.
class Valuation::Name
  def initialize(valuation_kind, accountable_type)
    @valuation_kind = valuation_kind
    @accountable_type = accountable_type
  end

  def to_s
    case valuation_kind
    when "opening_anchor"
      opening_anchor_name
    when "current_anchor"
      current_anchor_name
    else
      recon_name
    end
  end

  private
    attr_reader :valuation_kind, :accountable_type

    # The start value on the account
    def opening_anchor_name
      case accountable_type
      when "Property"
        "Original purchase price"
      when "Loan"
        "Original principal"
      when "Investment"
        "Opening account value"
      else
        "Opening balance"
      end
    end

    # The current value on the account
    def current_anchor_name
      case accountable_type
      when "Property"
        "Current market value"
      when "Loan"
        "Current loan balance"
      when "Investment"
        "Current account value"
      else
        "Current balance"
      end
    end

    # Any "reconciliation" in the middle of the timeline, typically an "override" by the user to account
    # for missing entries that cause the balance to be incorrect.
    def recon_name
      case accountable_type
      when "Property", "Investment"
        "Manual value update"
      when "Loan"
        "Manual principal update"
      else
        "Manual balance update"
      end
    end
end

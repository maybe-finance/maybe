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

    def opening_anchor_name
      case accountable_type
      when "Property", "Vehicle"
        "Original purchase price"
      when "Loan"
        "Original principal"
      when "Investment", "Crypto", "OtherAsset"
        "Opening account value"
      else
        "Opening balance"
      end
    end

    def current_anchor_name
      case accountable_type
      when "Property", "Vehicle"
        "Current market value"
      when "Loan"
        "Current loan balance"
      when "Investment", "Crypto", "OtherAsset"
        "Current account value"
      else
        "Current balance"
      end
    end

    def recon_name
      case accountable_type
      when "Property", "Investment", "Vehicle", "Crypto", "OtherAsset"
        "Manual value update"
      when "Loan"
        "Manual principal update"
      else
        "Manual balance update"
      end
    end
end

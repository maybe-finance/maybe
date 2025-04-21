module AccountsHelper
  def summary_card(title:, &block)
    content = capture(&block)
    render "accounts/summary_card", title: title, content: content
  end
  
  # Format account subtype to be more friendly
  def format_account_subtype(subtype)
    return nil if subtype.nil?
    
    # Mapping of special cases
    special_cases = {
      "ira" => "IRA",
      "401k" => "401(k)",
      "hsa" => "HSA",
    }
    
    # Convert to title case
    subtype_string = subtype.titleize
    
    special_cases.each do |key, value|
      # Use word boundaries to ensure we're replacing whole words
      subtype_string = subtype_string.gsub(/\b#{key}\b/i, value)
    end
    
    subtype_string
  end
end

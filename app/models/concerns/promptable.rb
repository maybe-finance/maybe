module Promptable
  extend ActiveSupport::Concern

  # Convert model data to a format that's readable by AI
  def to_ai_readable_hash
    raise NotImplementedError, "#{self.class} must implement to_ai_readable_hash"
  end

  private

    # Format currency values consistently for AI display
    def format_currency(amount, currency = family.currency)
      Money.new(amount, currency).format
    end
end

module Transaction::Ruleable
  extend ActiveSupport::Concern

  def eligible_for_category_rule?
    rules.joins(:actions).where(
      actions: {
        action_type: "set_transaction_category",
        value: category_id
      }
    ).empty?
  end

  private
    def rules
      entry.account.family.rules
    end
end

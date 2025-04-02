class Rule::Action < ApplicationRecord
  UnsupportedActionError = Class.new(StandardError)

  belongs_to :rule

  validates :action_type, presence: true

  def apply(resource_scope)
    case action_type
    when "set_transaction_category"
      category = rule.family.categories.find(value)
      resource_scope.update_all(category_id: category.id, updated_at: Time.current)
    when "set_transaction_tags"
      # TODO
    when "set_transaction_frequency"
      # TODO
    when "ai_enhance_transaction_name"
      # TODO
    when "ai_categorize_transaction"
      # TODO
    else
      raise UnsupportedActionError, "Unsupported action type: #{action_type}"
    end
  end
end

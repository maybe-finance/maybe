class Rule::Action::TransactionRegistry
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def get_config(action_type)
    ActionConfig.new(**definitions[action_type.to_sym])
  end

  def as_json
    definitions.map do |action_type, data|
      {
        label: data[:label],
        action_type: action_type
      }
    end
  end

  private
    ActionConfig = Data.define(:label, :options, :builder)

    def definitions
      {
        set_transaction_category: {
          label: "Set category",
          options: family.categories.pluck(:name, :id),
          builder: ->(transaction_scope, value) {
            category = family.categories.find(value)
            transaction_scope.update_all(category_id: category.id, updated_at: Time.current)
          }
        },
        set_transaction_tags: {
          label: "Set tags",
          options: family.tags.pluck(:name, :id),
          builder: ->(transaction_scope, value) {
            # TODO
          }
        },
        set_transaction_frequency: {
          label: "Set frequency",
          options: [
            [ "One-time", "one_time" ],
            [ "Recurring", "recurring" ]
          ],
          builder: ->(transaction_scope, value) {
            # TODO
          }
        },
        ai_enhance_transaction_name: {
          label: "AI enhance name",
          builder: ->(transaction_scope, value) {
            # TODO
          }
        },
        ai_categorize_transaction: {
          label: "AI categorize",
          builder: ->(transaction_scope, value) {
            # TODO
          }
        }
      }
    end
end

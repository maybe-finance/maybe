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
        input_type: data[:input_type],
        label: data[:label],
        action_type: action_type,
        options: data[:options]
      }
    end
  end

  def options
    definitions.map do |action_type, data|
      [ data[:label], action_type ]
    end
  end

  private
    ActionConfig = Data.define(:input_type, :label, :options, :builder)

    def definitions
      {
        set_transaction_category: {
          input_type: "select",
          label: "Set category",
          options: family.categories.pluck(:name, :id),
          builder: ->(transaction_scope, value) {
            category = family.categories.find(value)
            transaction_scope.update_all(category_id: category.id, updated_at: Time.current)
          }
        },
        set_transaction_tags: {
          input_type: "select",
          label: "Set tags",
          options: family.tags.pluck(:name, :id),
          builder: ->(transaction_scope, value) {
            # TODO
          }
        },
        set_transaction_frequency: {
          input_type: "select",
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
          input_type: nil,
          label: "AI enhance name",
          builder: ->(transaction_scope, value) {
            # TODO
          }
        },
        ai_categorize_transaction: {
          input_type: nil,
          label: "AI categorize",
          builder: ->(transaction_scope, value) {
            # TODO
          }
        }
      }
    end
end

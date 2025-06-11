class Demo::RuleGenerator
  include Demo::DataHelper

  def create_rules!(family)
    tags = create_tags!(family)
    categories = create_categories!(family)
    merchants = create_merchants!(family)

    rules = []

    if merchants.any? && categories.any?
      rule = family.rules.create!(
        name: "Auto-categorize Grocery Purchases",
        resource_type: "Transaction",
        conditions: [
          Rule::Condition.new(condition_type: "merchant_name", operator: "contains", value: "Whole Foods")
        ],
        actions: [
          Rule::Action.new(action_type: "category_id", value: categories.first.id.to_s)
        ]
      )
      rules << rule
    end

    rules
  end

  def create_tags!(family)
    tag_names = [ "Business", "Tax Deductible", "Recurring", "Emergency" ]
    tags = []

    tag_names.each do |name|
      tag = family.tags.find_or_create_by!(name: name) do |t|
        t.color = random_color
      end
      tags << tag
    end

    tags
  end

  def create_categories!(family)
    category_data = [
      { name: "Groceries", color: random_color },
      { name: "Transportation", color: random_color },
      { name: "Entertainment", color: random_color },
      { name: "Utilities", color: random_color },
      { name: "Healthcare", color: random_color }
    ]

    categories = []
    category_data.each do |data|
      category = family.categories.find_or_create_by!(name: data[:name]) do |c|
        c.color = data[:color]
      end
      categories << category
    end

    categories
  end

  def create_merchants!(family)
    merchant_names = [
      "Whole Foods Market",
      "Shell Gas Station",
      "Netflix",
      "Electric Company",
      "Local Coffee Shop"
    ]

    merchants = []
    merchant_names.each do |name|
      merchant = family.merchants.find_or_create_by!(name: name)
      merchants << merchant
    end

    merchants
  end
end

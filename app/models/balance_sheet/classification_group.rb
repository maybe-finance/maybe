class BalanceSheet::ClassificationGroup
  include Monetizable

  monetize :total, as: :total_money

  attr_reader :classification, :currency

  def initialize(classification:, currency:, accounts:)
    @classification = normalize_classification!(classification)
    @name = name
    @currency = currency
    @accounts = accounts
  end

  def name
    classification.titleize.pluralize
  end

  def icon
    classification == "asset" ? "plus" : "minus"
  end

  def total
    accounts.sum(&:converted_balance)
  end

  def syncing?
    accounts.any?(&:syncing?)
  end

  # For now, we group by accountable type. This can be extended in the future to support arbitrary user groupings.
  def account_groups
    groups = accounts.group_by(&:accountable_type)
                     .transform_keys { |at| Accountable.from_type(at) }
                     .map do |accountable, account_rows|
                       BalanceSheet::AccountGroup.new(
                         name: accountable.display_name,
                         color: accountable.color,
                         accountable_type: accountable,
                         accounts: account_rows,
                         classification_group: self
                       )
                     end

    # Sort the groups using the manual order defined by Accountable::TYPES so that
    # the UI displays account groups in a predictable, domain-specific sequence.
    groups.sort_by do |group|
      manual_order = Accountable::TYPES
      type_name    = group.key.camelize
      manual_order.index(type_name) || Float::INFINITY
    end
  end

  private
    attr_reader :accounts

    def normalize_classification!(classification)
      raise ArgumentError, "Invalid classification: #{classification}" unless %w[asset liability].include?(classification)
      classification
    end
end

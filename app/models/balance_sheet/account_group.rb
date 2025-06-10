class BalanceSheet::AccountGroup
  include Monetizable

  monetize :total, as: :total_money

  attr_reader :name, :color, :accountable_type, :accounts

  def initialize(name:, color:, accountable_type:, accounts:, classification_group:)
    @name = name
    @color = color
    @accountable_type = accountable_type
    @accounts = accounts
    @classification_group = classification_group
  end

  # A stable DOM id for this group.
  # Example outputs:
  #   dom_id(tab: :asset)               # => "asset_depository"
  #   dom_id(tab: :all, mobile: true)   # => "mobile_all_depository"
  #
  # Keeping all of the logic here means the view layer and broadcaster only
  # need to ask the object for its DOM id instead of rebuilding string
  # fragments in multiple places.
  def dom_id(tab: nil, mobile: false)
    parts = []
    parts << "mobile" if mobile
    parts << (tab ? tab.to_s : classification.to_s)
    parts << key
    parts.compact.join("_")
  end

  def key
    accountable_type.to_s.underscore
  end

  def total
    accounts.sum(&:converted_balance)
  end

  def weight
    return 0 if classification_group.total.zero?

    total / classification_group.total.to_d * 100
  end

  def syncing?
    accounts.any?(&:syncing?)
  end

  # "asset" or "liability"
  def classification
    classification_group.classification
  end

  def currency
    classification_group.currency
  end

  private
    attr_reader :classification_group
end

class Rule < ApplicationRecord
  UnsupportedResourceTypeError = Class.new(StandardError)

  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  validates :resource_type, presence: true

  def apply
    scope = resource_scope

    conditions.each do |condition|
      scope = condition.apply(scope)
    end

    actions.each do |action|
      action.apply(scope)
    end
  end

  def resource_scope
    case resource_type
    when "transaction"
      family.transactions
            .active
            .with_entry
            .where(account_entries: { date: effective_date..nil })
    else
      raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
    end
  end
end

class Rule < ApplicationRecord
  RESOURCE_TYPES = %w[transaction].freeze

  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  validates :effective_date, presence: true
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }

  def apply
    scope = resource_scope

    conditions.each do |condition|
      scope = condition.apply(scope)
    end

    actions.each do |action|
      action.apply(scope)
    end
  end

  private
    def resource_scope
      case resource_type
      when "transaction"
        family.transactions
      end
    end
end

module Account::Entryable
  extend ActiveSupport::Concern

  included do
    has_one :entry, as: :entryable, touch: true

    delegate :name, to: :entry
    delegate :date, to: :entry
    delegate :amount, to: :entry
    delegate :currency, to: :entry

    has_one :account, through: :entry, class_name: "Account"

    default_scope -> { includes(:entry) }
  end
end

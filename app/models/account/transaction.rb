class Account::Transaction < ApplicationRecord
  include Account::Entryable, Transferable

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true

  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  accepts_nested_attributes_for :taggings, allow_destroy: true

  class << self
    def search(params)
      Account::TransactionSearch.new(params).build_query(all)
    end

    def with_default_inclusions
      includes(
        { entry: :account },
        :category, :merchant, :tags, :transfer_as_outflow, :transfer_as_inflow
      )
    end
  end
end

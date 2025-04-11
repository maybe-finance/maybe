class Account::Transaction < ApplicationRecord
  include Account::Entryable, Transferable, Ruleable, LockableAttributes

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true

  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  accepts_nested_attributes_for :taggings, allow_destroy: true

  class << self
    def search(params)
      Account::TransactionSearch.new(params).build_query(all)
    end
  end
end

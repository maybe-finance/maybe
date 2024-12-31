class Account::Transaction < ApplicationRecord
  include Account::Entryable

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  has_one :transfer_as_inflow, class_name: "Transfer", foreign_key: "inflow_transaction_id", dependent: :restrict_with_exception
  has_one :transfer_as_outflow, class_name: "Transfer", foreign_key: "outflow_transaction_id", dependent: :restrict_with_exception

  accepts_nested_attributes_for :taggings, allow_destroy: true

  scope :active, -> { where(excluded: false) }

  class << self
    def search(params)
      Account::TransactionSearch.new(params).build_query(all)
    end
  end

  def transfer
    transfer_as_inflow || transfer_as_outflow
  end

  def transfer?
    transfer.present?
  end
end

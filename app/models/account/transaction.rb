class Account::Transaction < ApplicationRecord
  include Account::Entryable

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  accepts_nested_attributes_for :taggings, allow_destroy: true

  scope :active, -> { where(excluded: false) }

  class << self
    def search(params)
      query = all
      query = query.joins("LEFT JOIN categories ON categories.id = account_transactions.category_id").where(categories: { name: params[:categories] }) if params[:categories].present?
      query = query.joins("LEFT JOIN merchants ON merchants.id = account_transactions.merchant_id").where(merchants: { name: params[:merchants] }) if params[:merchants].present?
      query
    end

    def requires_search?(params)
      searchable_keys.any? { |key| params.key?(key) }
    end

    private

      def searchable_keys
        %i[categories merchants]
      end
  end

  private
    def previous_transaction_date
      self.account
          .transactions
          .where("date < ?", date)
          .order(date: :desc)
          .first&.date
    end
end

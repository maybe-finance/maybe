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
      if params[:categories].present?
        if params[:categories].exclude?("Uncategorized")
          query = query
                    .joins(:category)
                    .where(categories: { name: params[:categories] })
        else
          query = query
                    .left_joins(:category)
                    .where(categories: { name: params[:categories] })
                    .or(query.where(category_id: nil))
        end
      end

      query = query.joins(:merchant).where(merchants: { name: params[:merchants] }) if params[:merchants].present?

      if params[:tags].present?
        query = query.joins(:tags)
                     .where(tags: { name: params[:tags] })
                     .distinct
      end

      query
    end

    def requires_search?(params)
      searchable_keys.any? { |key| params.key?(key) }
    end

    private

      def searchable_keys
        %i[categories merchants tags]
      end
  end

  def name
    entry.name || "(no description)"
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

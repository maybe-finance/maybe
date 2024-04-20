class Transaction < ApplicationRecord
  include Monetizable

  belongs_to :account
  belongs_to :category, optional: true

  validates :name, :date, :amount, :account, presence: true

  monetize :amount

  scope :inflows, -> { where("amount > 0") }
  scope :outflows, -> { where("amount < 0") }
  scope :active, -> { where(excluded: false) }

  def self.ransackable_attributes(auth_object = nil)
    %w[name amount date]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category account]
  end

  def self.build_filter_list(params, family)
    filters = []

    date_filters = { gteq: nil, lteq: nil }

    if params
      params.each do |key, value|
        next if value.blank?

        case key
        when "account_id_in"
          value.each do |account_id|
            filters << { type: "account", value: family.accounts.find(account_id), original: { key: key, value: account_id } }
          end
        when "category_id_in"
          value.each do |category_id|
            filters << { type: "category", value: family.transaction_categories.find(category_id), original: { key: key, value: category_id } }
          end
        when "category_name_or_account_name_or_name_cont"
          filters << { type: "search", value: value, original: { key: key, value: nil } }
        when "date_gteq"
          date_filters[:gteq] = value
        when "date_lteq"
          date_filters[:lteq] = value
        end
      end

      unless date_filters.values.compact.empty?
        filters << { type: "date_range", value: date_filters, original: { key: "date_range", value: nil } }
      end
    end

    filters
  end
end

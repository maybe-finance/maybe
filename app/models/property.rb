class Property < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Single Family Home", "single_family_home" ],
    [ "Multi-Family Home", "multi_family_home" ],
    [ "Condominium", "condominium" ],
    [ "Townhouse", "townhouse" ],
    [ "Investment Property", "investment_property" ]
  ]

  has_one :address, as: :addressable, dependent: :destroy

  accepts_nested_attributes_for :address

  attribute :area_unit, :string, default: "sqft"

  def area
    Measurement.new(area_value, area_unit) if area_value.present?
  end

  def purchase_price
    first_valuation_amount
  end

  def trend
    TimeSeries::Trend.new(current: account.balance_money, previous: first_valuation_amount)
  end

  def color
    "#06AED4"
  end

  def icon
    "home"
  end

  private
    def first_valuation_amount
      account.entries.account_valuations.order(:date).first&.amount_money || account.balance_money
    end
end

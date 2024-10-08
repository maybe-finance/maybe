class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  def to_s
    I18n.t("address.format",
      line1: line1,
      line2: line2,
      county: county,
      locality: locality,
      region: region,
      country: country,
      postal_code: postal_code
    )
  end
end

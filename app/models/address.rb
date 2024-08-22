class Address < ApplicationRecord
    belongs_to :addressable, polymorphic: true

    validates :line1, :locality, presence: true
    validates :region, presence: true, format: { with: /\A[A-Z]{1,3}(-[A-Z\d]{1,3})?\z/, message: "must be a valid ISO3166-2 code" }
    validates :country, presence: true, format: { with: /\A[A-Z]{2}\z/, message: "must be a valid ISO3166-1 Alpha-2 code" }
    validates :postal_code, presence: true, if: :postal_code_required?

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

    private

    def postal_code_required?
        country.in?(%w[US CA GB])
    end
end

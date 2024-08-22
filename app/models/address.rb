class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  validates :line1, :locality, presence: true
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

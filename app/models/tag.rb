class Tag < ApplicationRecord
  belongs_to :family
  has_many :taggings, dependent: :destroy
  has_many :transactions, through: :taggings, source: :taggable, source_type: "Transaction"
  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"

  validates :name, presence: true, uniqueness: { scope: :family }

  scope :alphabetically, -> { order(:name) }

  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]

  UNCATEGORIZED_COLOR = "#737373"

  def replace_and_destroy!(replacement)
    transaction do
      raise ActiveRecord::RecordInvalid, "Replacement tag cannot be the same as the tag being destroyed" if replacement == self

      if replacement
        taggings.update_all tag_id: replacement.id
      end

      destroy!
    end
  end
end

class Import::Mapping < ApplicationRecord
  belongs_to :import
  belongs_to :mappable, polymorphic: true, optional: true

  validates :key, presence: true, uniqueness: { scope: [ :import_id, :type ] }

  scope :for_import, ->(import) { where(import: import).order(:key) }
  scope :creational, -> { where(create_when_empty: true, mappable: nil) }

  def selectable_values
    raise NotImplementedError, "Subclass must implement selectable_values"
  end

  def values_count
    raise NotImplementedError, "Subclass must implement values_count"
  end

  def mappable_class
    nil
  end

  def find_or_create_mappable!
    return mappable if mappable.present?
    return nil unless create_when_empty

    create_mappable!
  end

  def create_mappable!
    raise NotImplementedError, "Subclass must implement create_mappable!"
  end
end

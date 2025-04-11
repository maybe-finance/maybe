# Marks model attributes as "locked" so Rules and other external data enrichment
# sources know which attributes they can modify.
module LockableAttributes
  extend ActiveSupport::Concern

  included do
    scope :attributes_unlocked, ->(attrs) {
      attrs = Array(attrs).map(&:to_s)
      json_condition = attrs.each_with_object({}) { |attr, hash| hash[attr] = true }
      where.not(Arel.sql("#{table_name}.locked_fields ?| array[:keys]"), keys: attrs)
    }
  end

  def locked?(attr)
    locked_fields[attr.to_s] == true
  end

  def lock!(attr)
    update!(locked_fields: locked_fields.merge(attr.to_s => true))
  end

  def unlock!(attr)
    update!(locked_fields: locked_fields.except(attr.to_s))
  end

  def attribute_unlocked(attr)
    !locked?(attr)
  end
end

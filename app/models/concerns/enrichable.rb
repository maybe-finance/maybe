# Enrichable models can have 1+ of their fields enriched by various
# external sources (i.e. Plaid) or internal sources (i.e. Rules)
#
# This module defines how models should, lock, unlock, and edit attributes
# based on the source of the edit.  User edits always take highest precedence.
#
# For example:
#
# If a Rule tells us to set the category to "Groceries", but the user later overrides
# a transaction with a category of "Food", we should not override the category again.
#
module Enrichable
  extend ActiveSupport::Concern

  InvalidAttributeError = Class.new(StandardError)

  included do
    scope :enrichable, ->(attrs) {
      attrs = Array(attrs).map(&:to_s)
      json_condition = attrs.each_with_object({}) { |attr, hash| hash[attr] = true }
      where.not(Arel.sql("#{table_name}.locked_attributes ?| array[:keys]"), keys: attrs)
    }
  end

  def log_enrichment!(attribute_name:, attribute_value:, source:, metadata: {})
    de = DataEnrichment.find_or_create_by!(
      enrichable: self,
      attribute_name: attribute_name,
      source: source,
    )

    de.value = attribute_value
    de.metadata = metadata
    de.save!
  end

  def locked?(attr)
    locked_attributes[attr.to_s].present?
  end

  def enrichable?(attr)
    !locked?(attr)
  end

  def lock!(attr)
    update!(locked_attributes: locked_attributes.merge(attr.to_s => Time.current))
  end

  def unlock!(attr)
    update!(locked_attributes: locked_attributes.except(attr.to_s))
  end

  def lock_saved_attributes!
    saved_changes.keys.reject { |attr| ignored_enrichable_attributes.include?(attr) }.each do |attr|
      lock!(attr)
    end
  end

  private
    def ignored_enrichable_attributes
      %w[id updated_at created_at]
    end
end

class Holding < ApplicationRecord
  belongs_to :account
  belongs_to :security
  belongs_to :family

  after_update :log_changes

  private

  def log_changes
    ignored_attributes = ['updated_at']

    saved_changes.except(*ignored_attributes).each do |attr, (old_val, new_val)|
      ChangeLog.create(
        record_type: self.class.name,
        record_id: id,
        attribute_name: attr,
        old_value: old_val,
        new_value: new_val
      )
    end
  end
end

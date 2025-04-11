class AddParentSyncs < ActiveRecord::Migration[7.2]
  def change
    add_reference :syncs, :parent, foreign_key: { to_table: :syncs }, type: :uuid
  end
end

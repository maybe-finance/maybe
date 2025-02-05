class AddErrorTraceToSyncs < ActiveRecord::Migration[7.2]
  def change
    add_column :syncs, :error_backtrace, :text, array: true
  end
end

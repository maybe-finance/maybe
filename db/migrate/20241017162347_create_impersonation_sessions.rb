class CreateImpersonationSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :impersonation_sessions, id: :uuid do |t|
      t.references :impersonator, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :impersonated, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end

    add_reference :sessions, :active_impersonator_session, type: :uuid, foreign_key: { to_table: :impersonation_sessions }
  end
end

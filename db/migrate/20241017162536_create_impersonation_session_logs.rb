class CreateImpersonationSessionLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :impersonation_session_logs, id: :uuid do |t|
      t.references :impersonation_session, type: :uuid, foreign_key: true, null: false
      t.string :controller
      t.string :action
      t.text :path
      t.string :method
      t.string :ip_address
      t.text :user_agent
      t.timestamps
    end
  end
end

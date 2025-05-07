class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid

      t.string :status, null: false

      t.string :stripe_id
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency
      t.string :interval

      t.datetime :current_period_ends_at
      t.datetime :trial_ends_at

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        if Rails.application.config.app_mode.managed?
          execute <<~SQL
            INSERT INTO subscriptions (family_id, status, trial_ends_at, created_at, updated_at)
            SELECT
              f.id,
              CASE
                WHEN f.trial_started_at IS NOT NULL THEN 'trialing'
                ELSE COALESCE(f.stripe_subscription_status, 'incomplete')
              END,
              CASE
                WHEN f.trial_started_at IS NOT NULL THEN f.trial_started_at + INTERVAL '14 days'
                ELSE NULL
              END,
              now(),
              now()
            FROM families f
          SQL
        end
      end
    end

    remove_column :families, :stripe_subscription_status, :string
    remove_column :families, :trial_started_at, :datetime
    remove_column :families, :stripe_plan_id, :string
  end
end

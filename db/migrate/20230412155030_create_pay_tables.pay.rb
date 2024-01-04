# This migration comes from pay (originally 1)
class CreatePayTables < ActiveRecord::Migration[6.0]
  def change
    create_table :pay_customers, id: :uuid do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: :uuid
      t.string :processor, null: false
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :pay_customers, [:owner_type, :owner_id, :deleted_at, :default], name: :pay_customer_owner_index
    add_index :pay_customers, [:processor, :processor_id], unique: true

    create_table :pay_merchants, id: :uuid do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: :uuid
      t.string :processor, null: false
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data
      t.timestamps
    end
    add_index :pay_merchants, [:owner_type, :owner_id, :processor]

    create_table :pay_payment_methods, id: :uuid do |t|
      t.belongs_to :customer, foreign_key: {to_table: :pay_customers}, null: false, index: false, type: :uuid
      t.string :processor_id, null: false
      t.boolean :default
      t.string :type
      t.public_send Pay::Adapter.json_column_type, :data
      t.timestamps
    end
    add_index :pay_payment_methods, [:customer_id, :processor_id], unique: true

    create_table :pay_subscriptions, id: :uuid do |t|
      t.belongs_to :customer, foreign_key: {to_table: :pay_customers}, null: false, index: false, type: :uuid
      t.string :name, null: false
      t.string :processor_id, null: false
      t.string :processor_plan, null: false
      t.integer :quantity, default: 1, null: false
      t.string :status, null: false
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_ends_at
      t.datetime :ends_at
      t.boolean :metered
      t.string :pause_behavior
      t.datetime :pause_starts_at
      t.datetime :pause_resumes_at
      t.decimal :application_fee_percent, precision: 8, scale: 2
      t.public_send Pay::Adapter.json_column_type, :metadata
      t.public_send Pay::Adapter.json_column_type, :data
      t.timestamps
    end
    add_index :pay_subscriptions, [:customer_id, :processor_id], unique: true
    add_index :pay_subscriptions, [:metered]
    add_index :pay_subscriptions, [:pause_starts_at]

    create_table :pay_charges, id: :uuid do |t|
      t.belongs_to :customer, foreign_key: {to_table: :pay_customers}, null: false, index: false, type: :uuid
      t.belongs_to :subscription, foreign_key: {to_table: :pay_subscriptions}, null: true, type: :uuid
      t.string :processor_id, null: false
      t.integer :amount, null: false
      t.string :currency
      t.integer :application_fee_amount
      t.integer :amount_refunded
      t.public_send Pay::Adapter.json_column_type, :metadata
      t.public_send Pay::Adapter.json_column_type, :data
      t.timestamps
    end
    add_index :pay_charges, [:customer_id, :processor_id], unique: true

    create_table :pay_webhooks, id: :uuid do |t|
      t.string :processor
      t.string :event_type
      t.public_send Pay::Adapter.json_column_type, :event
      t.timestamps
    end
  end
end

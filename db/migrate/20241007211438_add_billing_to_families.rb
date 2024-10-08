class AddBillingToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :stripe_plan_id, :string
    add_column :families, :stripe_customer_id, :string
    add_column :families, :stripe_subscription_status, :string, default: "incomplete"
  end
end

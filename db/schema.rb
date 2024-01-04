# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_05_01_164317) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "source_id"
    t.boolean "is_active", default: true
    t.string "kind"
    t.string "subkind"
    t.uuid "connection_id", null: false
    t.decimal "available_balance", precision: 19, scale: 4
    t.decimal "current_balance", precision: 19, scale: 4
    t.string "currency_code"
    t.integer "sync_status", default: 0
    t.string "mask"
    t.integer "source"
    t.date "current_balance_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "official_name"
    t.decimal "credit_limit", precision: 10, scale: 2
    t.jsonb "property_details", default: {}
    t.boolean "auto_valuation", default: false
    t.uuid "family_id"
    t.index ["connection_id"], name: "index_accounts_on_connection_id"
    t.index ["family_id"], name: "index_accounts_on_family_id"
  end

  create_table "balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "security_id"
    t.decimal "balance", precision: 23, scale: 8
    t.decimal "quantity", precision: 36, scale: 18
    t.decimal "cost_basis", precision: 23, scale: 8
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "change", precision: 23, scale: 8, default: "0.0"
    t.string "kind"
    t.uuid "family_id"
    t.index ["account_id", "security_id", "date", "kind", "family_id"], name: "index_balances_on_account_id_security_id_date_kind_family_id", unique: true
    t.index ["account_id", "security_id", "date"], name: "index_balances_on_account_id_and_security_id_and_date", unique: true
    t.index ["account_id"], name: "index_balances_on_account_id"
    t.index ["family_id"], name: "index_balances_on_family_id"
    t.index ["security_id"], name: "index_balances_on_security_id"
  end

  create_table "change_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "record_type"
    t.uuid "record_id"
    t.string "attribute_name"
    t.decimal "old_value", precision: 36, scale: 18
    t.decimal "new_value", precision: 36, scale: 18
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "source"
    t.uuid "user_id", null: false
    t.integer "status"
    t.integer "sync_status"
    t.jsonb "error"
    t.boolean "new_accounts_available"
    t.datetime "consent_expiration"
    t.string "aggregator_id"
    t.string "item_id"
    t.string "access_token"
    t.string "cursor"
    t.datetime "investments_last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plaid_products", default: [], array: true
    t.uuid "family_id"
    t.index ["family_id"], name: "index_connections_on_family_id"
    t.index ["user_id"], name: "index_connections_on_user_id"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "summary"
    t.uuid "user_id", null: false
    t.string "status"
    t.string "role"
    t.string "kind"
    t.string "subkind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "families", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "demographics", default: {}
    t.string "country"
    t.string "region"
    t.string "currency", default: "USD"
    t.string "household"
    t.string "risk"
    t.text "goals"
    t.boolean "agreed", default: false
    t.datetime "agreed_at"
    t.jsonb "agreements", default: {}
  end

  create_table "holdings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "security_id", null: false
    t.decimal "value", precision: 19, scale: 4
    t.decimal "quantity", precision: 36, scale: 18
    t.decimal "cost_basis_source", precision: 23, scale: 8
    t.string "currency_code"
    t.string "source_id"
    t.boolean "excluded", default: false
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "family_id"
    t.index ["account_id", "security_id"], name: "index_holdings_on_account_id_and_security_id", unique: true
    t.index ["account_id"], name: "index_holdings_on_account_id"
    t.index ["family_id"], name: "index_holdings_on_family_id"
    t.index ["security_id"], name: "index_holdings_on_security_id"
  end

  create_table "institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "logo"
    t.string "color"
    t.string "url"
    t.string "provider"
    t.string "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_institutions_on_provider_id", unique: true
  end

  create_table "investment_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "security_id", null: false
    t.date "date"
    t.string "name"
    t.decimal "amount", precision: 19, scale: 4
    t.decimal "quantity", precision: 36, scale: 18
    t.decimal "price", precision: 23, scale: 8
    t.string "currency_code"
    t.string "source_transaction_id"
    t.string "source_type"
    t.string "source_subtype"
    t.decimal "fees", precision: 19, scale: 4
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_investment_transactions_on_account_id"
    t.index ["security_id"], name: "index_investment_transactions_on_security_id"
    t.index ["source_transaction_id"], name: "index_investment_transactions_on_source_transaction_id", unique: true
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.uuid "user_id"
    t.string "role"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false
    t.text "log"
    t.string "status", default: "pending"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "kind", null: false
    t.decimal "amount", precision: 19, scale: 2
    t.uuid "user_id"
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "family_id"
    t.string "subkind"
    t.index ["family_id"], name: "index_metrics_on_family_id"
    t.index ["kind", "family_id", "date"], name: "index_metrics_on_kind_and_family_id_and_date", unique: true, where: "(subkind IS NULL)"
    t.index ["kind", "subkind", "family_id", "date"], name: "index_metrics_on_kind_and_subkind_and_family_id_and_date", unique: true, where: "(subkind IS NOT NULL)"
    t.index ["kind", "user_id", "date"], name: "index_metrics_on_kind_and_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_metrics_on_user_id"
  end

  create_table "pay_charges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.uuid "subscription_id"
    t.string "processor_id", null: false
    t.integer "amount", null: false
    t.string "currency"
    t.integer "application_fee_amount"
    t.integer "amount_refunded"
    t.jsonb "metadata"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "owner_type"
    t.uuid "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at", "default"], name: "pay_customer_owner_index"
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "owner_type"
    t.uuid "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.string "processor_id", null: false
    t.boolean "default"
    t.string "type"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.string "name", null: false
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.datetime "current_period_start", precision: nil
    t.datetime "current_period_end", precision: nil
    t.datetime "trial_ends_at", precision: nil
    t.datetime "ends_at", precision: nil
    t.boolean "metered"
    t.string "pause_behavior"
    t.datetime "pause_starts_at", precision: nil
    t.datetime "pause_resumes_at", precision: nil
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.jsonb "metadata"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "processor"
    t.string "event_type"
    t.jsonb "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prompts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content"
    t.string "categories", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "securities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.string "cusip"
    t.string "isin"
    t.string "currency_code"
    t.string "source", null: false
    t.string "source_id"
    t.string "source_type"
    t.decimal "shares_per_contract", precision: 36, scale: 19
    t.boolean "is_cash_equivalent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.decimal "real_time_price", precision: 10, scale: 2
    t.datetime "real_time_price_updated_at"
    t.string "logo"
    t.string "logo_source"
    t.string "sector"
    t.string "industry"
    t.string "website"
    t.text "logo_svg"
    t.jsonb "logo_colors", default: []
    t.index ["source", "source_id"], name: "index_securities_on_source_and_source_id", unique: true
    t.index ["source_id"], name: "index_securities_on_source_id", unique: true
  end

  create_table "security_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "security_id", null: false
    t.date "date", null: false
    t.decimal "open", precision: 20, scale: 11
    t.decimal "high", precision: 20, scale: 11
    t.decimal "low", precision: 20, scale: 11
    t.decimal "close", precision: 20, scale: 11
    t.string "currency", default: "USD"
    t.string "exchange"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["security_id", "date"], name: "index_security_prices_on_security_id_and_date", unique: true
    t.index ["security_id"], name: "index_security_prices_on_security_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.decimal "amount", precision: 19, scale: 2
    t.boolean "is_pending", default: false
    t.date "date"
    t.uuid "account_id", null: false
    t.string "currency_code"
    t.string "source_transaction_id"
    t.string "source_category_id"
    t.string "source_type"
    t.jsonb "categories"
    t.string "merchant_name"
    t.integer "flow", default: 0
    t.boolean "excluded", default: false
    t.string "payment_channel"
    t.jsonb "enrichment", default: {}
    t.datetime "enriched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "enrichment_country"
    t.jsonb "enrichment_intermediaries", default: {}
    t.string "enrichment_label_group"
    t.string "enrichment_label"
    t.string "enrichment_location"
    t.string "enrichment_logo"
    t.integer "enrichment_mcc"
    t.string "enrichment_merchant_name"
    t.string "enrichment_merchant_id"
    t.string "enrichment_merchant_website"
    t.string "enrichment_person"
    t.string "enrichment_recurrence"
    t.jsonb "enrichment_recurrence_group", default: {}
    t.uuid "family_id"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["family_id"], name: "index_transactions_on_family_id"
    t.index ["source_transaction_id"], name: "index_transactions_on_source_transaction_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "family_id", null: false
    t.string "plaid_link_token"
    t.datetime "plaid_link_token_expires_at"
    t.string "first_name"
    t.string "last_name"
    t.date "birthday"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["family_id"], name: "index_users_on_family_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "connections"
  add_foreign_key "accounts", "families"
  add_foreign_key "balances", "accounts"
  add_foreign_key "balances", "families"
  add_foreign_key "balances", "securities"
  add_foreign_key "connections", "families"
  add_foreign_key "connections", "users"
  add_foreign_key "conversations", "users"
  add_foreign_key "holdings", "accounts"
  add_foreign_key "holdings", "families"
  add_foreign_key "holdings", "securities"
  add_foreign_key "investment_transactions", "accounts"
  add_foreign_key "investment_transactions", "securities"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "metrics", "families"
  add_foreign_key "metrics", "users"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "security_prices", "securities"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "families"
  add_foreign_key "users", "families"
end

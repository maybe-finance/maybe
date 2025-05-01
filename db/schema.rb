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

ActiveRecord::Schema[7.2].define(version: 2025_05_01_172430) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_status", ["ok", "syncing", "error"]

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "subtype"
    t.uuid "family_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "accountable_type"
    t.uuid "accountable_id"
    t.decimal "balance", precision: 19, scale: 4
    t.string "currency"
    t.boolean "is_active", default: true, null: false
    t.virtual "classification", type: :string, as: "\nCASE\n    WHEN ((accountable_type)::text = ANY ((ARRAY['Loan'::character varying, 'CreditCard'::character varying, 'OtherLiability'::character varying])::text[])) THEN 'liability'::text\n    ELSE 'asset'::text\nEND", stored: true
    t.uuid "import_id"
    t.uuid "plaid_account_id"
    t.boolean "scheduled_for_deletion", default: false
    t.datetime "last_synced_at"
    t.decimal "cash_balance", precision: 19, scale: 4, default: "0.0"
    t.jsonb "locked_attributes", default: {}
    t.index ["accountable_id", "accountable_type"], name: "index_accounts_on_accountable_id_and_accountable_type"
    t.index ["accountable_type"], name: "index_accounts_on_accountable_type"
    t.index ["family_id", "accountable_type"], name: "index_accounts_on_family_id_and_accountable_type"
    t.index ["family_id", "id"], name: "index_accounts_on_family_id_and_id"
    t.index ["family_id"], name: "index_accounts_on_family_id"
    t.index ["import_id"], name: "index_accounts_on_import_id"
    t.index ["plaid_account_id"], name: "index_accounts_on_plaid_account_id"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "addressable_type"
    t.uuid "addressable_id"
    t.string "line1"
    t.string "line2"
    t.string "county"
    t.string "locality"
    t.string "region"
    t.string "country"
    t.integer "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.date "date", null: false
    t.decimal "balance", precision: 19, scale: 4, null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cash_balance", precision: 19, scale: 4, default: "0.0"
    t.index ["account_id", "date", "currency"], name: "index_account_balances_on_account_id_date_currency_unique", unique: true
    t.index ["account_id"], name: "index_balances_on_account_id"
  end

  create_table "budget_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "budget_id", null: false
    t.uuid "category_id", null: false
    t.decimal "budgeted_spending", precision: 19, scale: 4, null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "category_id"], name: "index_budget_categories_on_budget_id_and_category_id", unique: true
    t.index ["budget_id"], name: "index_budget_categories_on_budget_id"
    t.index ["category_id"], name: "index_budget_categories_on_category_id"
  end

  create_table "budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "budgeted_spending", precision: 19, scale: 4
    t.decimal "expected_income", precision: 19, scale: 4
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "start_date", "end_date"], name: "index_budgets_on_family_id_and_start_date_and_end_date", unique: true
    t.index ["family_id"], name: "index_budgets_on_family_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#6172F3", null: false
    t.uuid "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.string "classification", default: "expense", null: false
    t.string "lucide_icon", default: "shapes", null: false
    t.index ["family_id"], name: "index_categories_on_family_id"
  end

  create_table "chats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title", null: false
    t.string "instructions"
    t.jsonb "error"
    t.string "latest_assistant_response_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "credit_cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "available_credit", precision: 10, scale: 2
    t.decimal "minimum_payment", precision: 10, scale: 2
    t.decimal "apr", precision: 10, scale: 2
    t.date "expiration_date"
    t.decimal "annual_fee", precision: 10, scale: 2
    t.jsonb "locked_attributes", default: {}
  end

  create_table "cryptos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "data_enrichments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "enrichable_type", null: false
    t.uuid "enrichable_id", null: false
    t.string "source"
    t.string "attribute_name"
    t.jsonb "value"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrichable_id", "enrichable_type", "source", "attribute_name"], name: "idx_on_enrichable_id_enrichable_type_source_attribu_5be5f63e08", unique: true
    t.index ["enrichable_type", "enrichable_id"], name: "index_data_enrichments_on_enrichable"
  end

  create_table "depositories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "entryable_type"
    t.uuid "entryable_id"
    t.decimal "amount", precision: 19, scale: 4
    t.string "currency"
    t.date "date"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "import_id"
    t.text "notes"
    t.boolean "excluded", default: false
    t.string "plaid_id"
    t.jsonb "locked_attributes", default: {}
    t.index ["account_id"], name: "index_entries_on_account_id"
    t.index ["import_id"], name: "index_entries_on_import_id"
  end

  create_table "exchange_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "from_currency", null: false
    t.string "to_currency", null: false
    t.decimal "rate", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_currency", "to_currency", "date"], name: "index_exchange_rates_on_base_converted_date_unique", unique: true
    t.index ["from_currency"], name: "index_exchange_rates_on_from_currency"
    t.index ["to_currency"], name: "index_exchange_rates_on_to_currency"
  end

  create_table "families", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "USD"
    t.string "locale", default: "en"
    t.string "stripe_plan_id"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_status", default: "incomplete"
    t.string "date_format", default: "%m-%d-%Y"
    t.string "country", default: "US"
    t.datetime "last_synced_at"
    t.string "timezone"
    t.boolean "data_enrichment_enabled", default: false
    t.datetime "trial_started_at"
    t.boolean "early_access", default: false
  end

  create_table "holdings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "security_id", null: false
    t.date "date", null: false
    t.decimal "qty", precision: 19, scale: 4, null: false
    t.decimal "price", precision: 19, scale: 4, null: false
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "security_id", "date", "currency"], name: "idx_on_account_id_security_id_date_currency_5323e39f8b", unique: true
    t.index ["account_id"], name: "index_holdings_on_account_id"
    t.index ["security_id"], name: "index_holdings_on_security_id"
  end

  create_table "impersonation_session_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "impersonation_session_id", null: false
    t.string "controller"
    t.string "action"
    t.text "path"
    t.string "method"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["impersonation_session_id"], name: "index_impersonation_session_logs_on_impersonation_session_id"
  end

  create_table "impersonation_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "impersonator_id", null: false
    t.uuid "impersonated_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["impersonated_id"], name: "index_impersonation_sessions_on_impersonated_id"
    t.index ["impersonator_id"], name: "index_impersonation_sessions_on_impersonator_id"
  end

  create_table "import_mappings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", null: false
    t.string "key"
    t.string "value"
    t.boolean "create_when_empty", default: true
    t.uuid "import_id", null: false
    t.string "mappable_type"
    t.uuid "mappable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["import_id"], name: "index_import_mappings_on_import_id"
    t.index ["mappable_type", "mappable_id"], name: "index_import_mappings_on_mappable"
  end

  create_table "import_rows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "import_id", null: false
    t.string "account"
    t.string "date"
    t.string "qty"
    t.string "ticker"
    t.string "price"
    t.string "amount"
    t.string "currency"
    t.string "name"
    t.string "category"
    t.string "tags"
    t.string "entity_type"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "exchange_operating_mic"
    t.index ["import_id"], name: "index_import_rows_on_import_id"
  end

  create_table "imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "column_mappings"
    t.string "status"
    t.string "raw_file_str"
    t.string "normalized_csv_str"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "col_sep", default: ","
    t.uuid "family_id", null: false
    t.uuid "account_id"
    t.string "type", null: false
    t.string "date_col_label"
    t.string "amount_col_label"
    t.string "name_col_label"
    t.string "category_col_label"
    t.string "tags_col_label"
    t.string "account_col_label"
    t.string "qty_col_label"
    t.string "ticker_col_label"
    t.string "price_col_label"
    t.string "entity_type_col_label"
    t.string "notes_col_label"
    t.string "currency_col_label"
    t.string "date_format", default: "%m/%d/%Y"
    t.string "signage_convention", default: "inflows_positive"
    t.string "error"
    t.string "number_format"
    t.string "exchange_operating_mic_col_label"
    t.string "amount_type_strategy", default: "signed_amount"
    t.string "amount_type_inflow_value"
    t.index ["family_id"], name: "index_imports_on_family_id"
  end

  create_table "investments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "role"
    t.string "token"
    t.uuid "family_id", null: false
    t.uuid "inviter_id", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "family_id"], name: "index_invitations_on_email_and_family_id", unique: true
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["family_id"], name: "index_invitations_on_family_id"
    t.index ["inviter_id"], name: "index_invitations_on_inviter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "invite_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_invite_codes_on_token", unique: true
  end

  create_table "loans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rate_type"
    t.decimal "interest_rate", precision: 10, scale: 3
    t.integer "term_months"
    t.decimal "initial_balance", precision: 19, scale: 4
    t.jsonb "locked_attributes", default: {}
  end

  create_table "merchants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "color"
    t.uuid "family_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo_url"
    t.string "website_url"
    t.string "type", null: false
    t.string "source"
    t.string "provider_merchant_id"
    t.index ["family_id", "name"], name: "index_merchants_on_family_id_and_name", unique: true, where: "((type)::text = 'FamilyMerchant'::text)"
    t.index ["family_id"], name: "index_merchants_on_family_id"
    t.index ["source", "name"], name: "index_merchants_on_source_and_name", unique: true, where: "((type)::text = 'ProviderMerchant'::text)"
    t.index ["type"], name: "index_merchants_on_type"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_id", null: false
    t.string "type", null: false
    t.string "status", default: "complete", null: false
    t.text "content"
    t.string "ai_model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "debug", default: false
    t.string "provider_id"
    t.boolean "reasoning", default: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "other_assets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "other_liabilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "plaid_accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "plaid_item_id", null: false
    t.string "plaid_id"
    t.string "plaid_type"
    t.string "plaid_subtype"
    t.decimal "current_balance", precision: 19, scale: 4
    t.decimal "available_balance", precision: 19, scale: 4
    t.string "currency"
    t.string "name"
    t.string "mask"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plaid_item_id"], name: "index_plaid_accounts_on_plaid_item_id"
  end

  create_table "plaid_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.string "access_token"
    t.string "plaid_id"
    t.string "name"
    t.string "next_cursor"
    t.boolean "scheduled_for_deletion", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "available_products", default: [], array: true
    t.string "billed_products", default: [], array: true
    t.datetime "last_synced_at"
    t.string "plaid_region", default: "us", null: false
    t.string "institution_url"
    t.string "institution_id"
    t.string "institution_color"
    t.string "status", default: "good", null: false
    t.index ["family_id"], name: "index_plaid_items_on_family_id"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year_built"
    t.integer "area_value"
    t.string "area_unit"
    t.jsonb "locked_attributes", default: {}
  end

  create_table "rejected_transfers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inflow_transaction_id", null: false
    t.uuid "outflow_transaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inflow_transaction_id", "outflow_transaction_id"], name: "idx_on_inflow_transaction_id_outflow_transaction_id_412f8e7e26", unique: true
    t.index ["inflow_transaction_id"], name: "index_rejected_transfers_on_inflow_transaction_id"
    t.index ["outflow_transaction_id"], name: "index_rejected_transfers_on_outflow_transaction_id"
  end

  create_table "rule_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rule_id", null: false
    t.string "action_type", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_rule_actions_on_rule_id"
  end

  create_table "rule_conditions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rule_id"
    t.uuid "parent_id"
    t.string "condition_type", null: false
    t.string "operator", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_rule_conditions_on_parent_id"
    t.index ["rule_id"], name: "index_rule_conditions_on_rule_id"
  end

  create_table "rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.string "resource_type", null: false
    t.date "effective_date"
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_rules_on_family_id"
  end

  create_table "securities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ticker", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_code"
    t.string "exchange_mic"
    t.string "exchange_acronym"
    t.string "logo_url"
    t.string "exchange_operating_mic"
    t.index ["country_code"], name: "index_securities_on_country_code"
    t.index ["exchange_operating_mic"], name: "index_securities_on_exchange_operating_mic"
    t.index ["ticker", "exchange_operating_mic"], name: "index_securities_on_ticker_and_exchange_operating_mic", unique: true
  end

  create_table "security_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "date", null: false
    t.decimal "price", precision: 19, scale: 4, null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "security_id"
    t.index ["security_id", "date", "currency"], name: "index_security_prices_on_security_id_and_date_and_currency", unique: true
    t.index ["security_id"], name: "index_security_prices_on_security_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_impersonator_session_id"
    t.datetime "subscribed_at"
    t.jsonb "prev_transaction_page_params", default: {}
    t.index ["active_impersonator_session_id"], name: "index_sessions_on_active_impersonator_session_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "stock_exchanges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "acronym"
    t.string "mic", null: false
    t.string "country", null: false
    t.string "country_code", null: false
    t.string "city"
    t.string "website"
    t.string "timezone_name"
    t.string "timezone_abbr"
    t.string "timezone_abbr_dst"
    t.string "currency_code"
    t.string "currency_symbol"
    t.string "currency_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_stock_exchanges_on_country"
    t.index ["country_code"], name: "index_stock_exchanges_on_country_code"
    t.index ["currency_code"], name: "index_stock_exchanges_on_currency_code"
  end

  create_table "syncs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "syncable_type", null: false
    t.uuid "syncable_id", null: false
    t.datetime "last_ran_at"
    t.date "start_date"
    t.string "status", default: "pending"
    t.string "error"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "error_backtrace", array: true
    t.uuid "parent_id"
    t.index ["parent_id"], name: "index_syncs_on_parent_id"
    t.index ["syncable_type", "syncable_id"], name: "index_syncs_on_syncable"
  end

  create_table "taggings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tag_id", null: false
    t.string "taggable_type"
    t.uuid "taggable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "color", default: "#e99537", null: false
    t.uuid "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_tags_on_family_id"
  end

  create_table "tool_calls", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "message_id", null: false
    t.string "provider_id", null: false
    t.string "provider_call_id"
    t.string "type", null: false
    t.string "function_name"
    t.jsonb "function_arguments"
    t.jsonb "function_result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
  end

  create_table "trades", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "security_id", null: false
    t.decimal "qty", precision: 19, scale: 4
    t.decimal "price", precision: 19, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.jsonb "locked_attributes", default: {}
    t.index ["security_id"], name: "index_trades_on_security_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "category_id"
    t.uuid "merchant_id"
    t.jsonb "locked_attributes", default: {}
    t.string "plaid_category"
    t.string "plaid_category_detailed"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
  end

  create_table "transfers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inflow_transaction_id", null: false
    t.uuid "outflow_transaction_id", null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inflow_transaction_id", "outflow_transaction_id"], name: "idx_on_inflow_transaction_id_outflow_transaction_id_8cd07a28bd", unique: true
    t.index ["inflow_transaction_id"], name: "index_transfers_on_inflow_transaction_id"
    t.index ["outflow_transaction_id"], name: "index_transfers_on_outflow_transaction_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
    t.boolean "active", default: true, null: false
    t.datetime "onboarded_at"
    t.string "unconfirmed_email"
    t.string "otp_secret"
    t.boolean "otp_required", default: false, null: false
    t.string "otp_backup_codes", default: [], array: true
    t.boolean "show_sidebar", default: true
    t.string "default_period", default: "last_30_days", null: false
    t.uuid "last_viewed_chat_id"
    t.boolean "show_ai_sidebar", default: true
    t.boolean "ai_enabled", default: false, null: false
    t.string "theme", default: "system"
    t.boolean "rule_prompts_disabled", default: false
    t.datetime "rule_prompt_dismissed_at"
    t.text "goals", default: [], array: true
    t.datetime "set_onboarding_preferences_at"
    t.datetime "set_onboarding_goals_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["family_id"], name: "index_users_on_family_id"
    t.index ["last_viewed_chat_id"], name: "index_users_on_last_viewed_chat_id"
    t.index ["otp_secret"], name: "index_users_on_otp_secret", unique: true, where: "(otp_secret IS NOT NULL)"
  end

  create_table "valuations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "locked_attributes", default: {}
  end

  create_table "vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.integer "mileage_value"
    t.string "mileage_unit"
    t.string "make"
    t.string "model"
    t.jsonb "locked_attributes", default: {}
  end

  add_foreign_key "accounts", "families"
  add_foreign_key "accounts", "imports"
  add_foreign_key "accounts", "plaid_accounts"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "balances", "accounts", on_delete: :cascade
  add_foreign_key "budget_categories", "budgets"
  add_foreign_key "budget_categories", "categories"
  add_foreign_key "budgets", "families"
  add_foreign_key "categories", "families"
  add_foreign_key "chats", "users"
  add_foreign_key "entries", "accounts"
  add_foreign_key "entries", "imports"
  add_foreign_key "holdings", "accounts"
  add_foreign_key "holdings", "securities"
  add_foreign_key "impersonation_session_logs", "impersonation_sessions"
  add_foreign_key "impersonation_sessions", "users", column: "impersonated_id"
  add_foreign_key "impersonation_sessions", "users", column: "impersonator_id"
  add_foreign_key "import_rows", "imports"
  add_foreign_key "imports", "families"
  add_foreign_key "invitations", "families"
  add_foreign_key "invitations", "users", column: "inviter_id"
  add_foreign_key "merchants", "families"
  add_foreign_key "messages", "chats"
  add_foreign_key "plaid_accounts", "plaid_items"
  add_foreign_key "plaid_items", "families"
  add_foreign_key "rejected_transfers", "transactions", column: "inflow_transaction_id"
  add_foreign_key "rejected_transfers", "transactions", column: "outflow_transaction_id"
  add_foreign_key "rule_actions", "rules"
  add_foreign_key "rule_conditions", "rule_conditions", column: "parent_id"
  add_foreign_key "rule_conditions", "rules"
  add_foreign_key "rules", "families"
  add_foreign_key "security_prices", "securities"
  add_foreign_key "sessions", "impersonation_sessions", column: "active_impersonator_session_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "syncs", "syncs", column: "parent_id"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tags", "families"
  add_foreign_key "tool_calls", "messages"
  add_foreign_key "trades", "securities"
  add_foreign_key "transactions", "categories", on_delete: :nullify
  add_foreign_key "transactions", "merchants"
  add_foreign_key "transfers", "transactions", column: "inflow_transaction_id", on_delete: :cascade
  add_foreign_key "transfers", "transactions", column: "outflow_transaction_id", on_delete: :cascade
  add_foreign_key "users", "chats", column: "last_viewed_chat_id"
  add_foreign_key "users", "families"
end

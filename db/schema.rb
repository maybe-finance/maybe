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

ActiveRecord::Schema[7.2].define(version: 2024_10_09_132959) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_status", ["ok", "syncing", "error"]
  create_enum "import_status", ["pending", "importing", "complete", "failed"]
  create_enum "user_role", ["admin", "member"]

  create_table "account_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.date "date", null: false
    t.decimal "balance", precision: 19, scale: 4, null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "date", "currency"], name: "index_account_balances_on_account_id_date_currency_unique", unique: true
    t.index ["account_id"], name: "index_account_balances_on_account_id"
  end

  create_table "account_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "entryable_type"
    t.uuid "entryable_id"
    t.decimal "amount", precision: 19, scale: 4
    t.string "currency"
    t.date "date"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "transfer_id"
    t.boolean "marked_as_transfer", default: false, null: false
    t.uuid "import_id"
    t.text "notes"
    t.boolean "excluded", default: false
    t.index ["account_id"], name: "index_account_entries_on_account_id"
    t.index ["import_id"], name: "index_account_entries_on_import_id"
    t.index ["transfer_id"], name: "index_account_entries_on_transfer_id"
  end

  create_table "account_holdings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "security_id", null: false
    t.date "date"
    t.decimal "qty", precision: 19, scale: 4
    t.decimal "price", precision: 19, scale: 4
    t.decimal "amount", precision: 19, scale: 4
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "security_id", "date", "currency"], name: "idx_on_account_id_security_id_date_currency_234024c8e3", unique: true
    t.index ["account_id"], name: "index_account_holdings_on_account_id"
    t.index ["security_id"], name: "index_account_holdings_on_security_id"
  end

  create_table "account_syncs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "status", default: "pending", null: false
    t.date "start_date"
    t.datetime "last_ran_at"
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_syncs_on_account_id"
  end

  create_table "account_trades", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "security_id", null: false
    t.decimal "qty", precision: 19, scale: 4
    t.decimal "price", precision: 19, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.index ["security_id"], name: "index_account_trades_on_security_id"
  end

  create_table "account_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "category_id"
    t.uuid "merchant_id"
    t.index ["category_id"], name: "index_account_transactions_on_category_id"
    t.index ["merchant_id"], name: "index_account_transactions_on_merchant_id"
  end

  create_table "account_transfers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "account_valuations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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
    t.date "last_sync_date"
    t.uuid "institution_id"
    t.virtual "classification", type: :string, as: "\nCASE\n    WHEN ((accountable_type)::text = ANY ((ARRAY['Loan'::character varying, 'CreditCard'::character varying, 'OtherLiability'::character varying])::text[])) THEN 'liability'::text\n    ELSE 'asset'::text\nEND", stored: true
    t.uuid "import_id"
    t.index ["accountable_type"], name: "index_accounts_on_accountable_type"
    t.index ["family_id"], name: "index_accounts_on_family_id"
    t.index ["import_id"], name: "index_accounts_on_import_id"
    t.index ["institution_id"], name: "index_accounts_on_institution_id"
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

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#6172F3", null: false
    t.string "internal_category"
    t.uuid "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_categories_on_family_id"
  end

  create_table "credit_cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "available_credit", precision: 10, scale: 2
    t.decimal "minimum_payment", precision: 10, scale: 2
    t.decimal "apr", precision: 10, scale: 2
    t.date "expiration_date"
    t.decimal "annual_fee", precision: 10, scale: 2
  end

  create_table "cryptos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "depositories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exchange_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "from_currency", null: false
    t.string "to_currency", null: false
    t.decimal "rate"
    t.date "date"
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
    t.datetime "last_synced_at"
    t.string "locale", default: "en"
    t.string "stripe_plan_id"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_status", default: "incomplete"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
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
    t.index ["import_id"], name: "index_import_rows_on_import_id"
  end

  create_table "imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "column_mappings"
    t.enum "status", default: "pending", enum_type: "import_status"
    t.string "raw_file_str"
    t.string "normalized_csv_str"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "col_sep", default: ","
    t.uuid "family_id", null: false
    t.uuid "original_account_id"
    t.string "type", null: false
    t.string "date_col_label", default: "date"
    t.string "amount_col_label", default: "amount"
    t.string "name_col_label", default: "name"
    t.string "category_col_label", default: "category"
    t.string "tags_col_label", default: "tags"
    t.string "account_col_label", default: "account"
    t.string "qty_col_label", default: "qty"
    t.string "ticker_col_label", default: "ticker"
    t.string "price_col_label", default: "price"
    t.string "entity_type_col_label", default: "type"
    t.string "notes_col_label", default: "notes"
    t.string "currency_col_label", default: "currency"
    t.string "date_format", default: "%m/%d/%Y"
    t.string "signage_convention", default: "inflows_positive"
    t.string "error"
    t.index ["family_id"], name: "index_imports_on_family_id"
  end

  create_table "institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "logo_url"
    t.uuid "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.index ["family_id"], name: "index_institutions_on_family_id"
  end

  create_table "investments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invite_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_invite_codes_on_token", unique: true
  end

  create_table "issues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "issuable_type"
    t.uuid "issuable_id"
    t.string "type"
    t.integer "severity"
    t.datetime "last_observed_at"
    t.datetime "resolved_at"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issuable_type", "issuable_id"], name: "index_issues_on_issuable"
  end

  create_table "loans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rate_type"
    t.decimal "interest_rate", precision: 10, scale: 2
    t.integer "term_months"
  end

  create_table "merchants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#e99537", null: false
    t.uuid "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_merchants_on_family_id"
  end

  create_table "other_assets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "other_liabilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year_built"
    t.integer "area_value"
    t.string "area_unit"
  end

  create_table "securities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ticker"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "security_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ticker"
    t.date "date"
    t.decimal "price", precision: 19, scale: 4
    t.string "currency", default: "USD"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
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

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last_prompted_upgrade_commit_sha"
    t.string "last_alerted_upgrade_commit_sha"
    t.enum "role", default: "member", null: false, enum_type: "user_role"
    t.boolean "active", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["family_id"], name: "index_users_on_family_id"
  end

  create_table "vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.integer "mileage_value"
    t.string "mileage_unit"
    t.string "make"
    t.string "model"
  end

  add_foreign_key "account_balances", "accounts", on_delete: :cascade
  add_foreign_key "account_entries", "account_transfers", column: "transfer_id"
  add_foreign_key "account_entries", "accounts"
  add_foreign_key "account_entries", "imports"
  add_foreign_key "account_holdings", "accounts"
  add_foreign_key "account_holdings", "securities"
  add_foreign_key "account_syncs", "accounts"
  add_foreign_key "account_trades", "securities"
  add_foreign_key "account_transactions", "categories", on_delete: :nullify
  add_foreign_key "account_transactions", "merchants"
  add_foreign_key "accounts", "families"
  add_foreign_key "accounts", "imports"
  add_foreign_key "accounts", "institutions"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "families"
  add_foreign_key "import_rows", "imports"
  add_foreign_key "imports", "families"
  add_foreign_key "institutions", "families"
  add_foreign_key "merchants", "families"
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tags", "families"
  add_foreign_key "users", "families"
end

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: account_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_status AS ENUM (
    'ok',
    'syncing',
    'error'
);


--
-- Name: gen_uuid_v7(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_uuid_v7() RETURNS uuid
    LANGUAGE sql
    AS $$
  -- Replace the first 48 bits of a uuidv4 with the current
  -- number of milliseconds since 1970-01-01 UTC
  -- and set the "ver" field to 7 by setting additional bits
  select encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid()) placing
    substring(int8send((extract(epoch from clock_timestamp())*1000)::bigint) from 3)
    from 1 for 6),
  52, 1),
      53, 1), 'hex')::uuid;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    subtype character varying,
    family_id uuid NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    accountable_type character varying,
    accountable_id uuid,
    balance numeric(19,4),
    currency character varying,
    is_active boolean DEFAULT true NOT NULL,
    classification character varying GENERATED ALWAYS AS (
CASE
    WHEN ((accountable_type)::text = ANY (ARRAY[('Loan'::character varying)::text, ('CreditCard'::character varying)::text, ('OtherLiability'::character varying)::text])) THEN 'liability'::text
    ELSE 'asset'::text
END) STORED,
    import_id uuid,
    plaid_account_id uuid,
    scheduled_for_deletion boolean DEFAULT false,
    cash_balance numeric(19,4) DEFAULT 0.0,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id uuid NOT NULL,
    blob_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    blob_id uuid NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    addressable_type character varying,
    addressable_id uuid,
    line1 character varying,
    line2 character varying,
    county character varying,
    locality character varying,
    region character varying,
    country character varying,
    postal_code integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.balances (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    account_id uuid NOT NULL,
    date date NOT NULL,
    balance numeric(19,4) NOT NULL,
    currency character varying DEFAULT 'USD'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    cash_balance numeric(19,4) DEFAULT 0.0
);


--
-- Name: budget_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_categories (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    budget_id uuid NOT NULL,
    category_id uuid NOT NULL,
    budgeted_spending numeric(19,4) NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgets (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    family_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    budgeted_spending numeric(19,4),
    expected_income numeric(19,4),
    currency character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    name character varying NOT NULL,
    color character varying DEFAULT '#6172F3'::character varying NOT NULL,
    family_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    parent_id uuid,
    classification character varying DEFAULT 'expense'::character varying NOT NULL,
    lucide_icon character varying DEFAULT 'shapes'::character varying NOT NULL
);


--
-- Name: chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chats (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    user_id uuid NOT NULL,
    title character varying NOT NULL,
    instructions character varying,
    error jsonb,
    latest_assistant_response_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: credit_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_cards (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    available_credit numeric(10,2),
    minimum_payment numeric(10,2),
    apr numeric(10,2),
    expiration_date date,
    annual_fee numeric(10,2),
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: cryptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cryptos (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: data_enrichments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_enrichments (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    enrichable_type character varying NOT NULL,
    enrichable_id uuid NOT NULL,
    source character varying,
    attribute_name character varying,
    value jsonb,
    metadata jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: depositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.depositories (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entries (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    account_id uuid NOT NULL,
    entryable_type character varying,
    entryable_id uuid,
    amount numeric(19,4),
    currency character varying,
    date date,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    import_id uuid,
    notes text,
    excluded boolean DEFAULT false,
    plaid_id character varying,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    from_currency character varying NOT NULL,
    to_currency character varying NOT NULL,
    rate numeric NOT NULL,
    date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.families (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    currency character varying DEFAULT 'USD'::character varying,
    locale character varying DEFAULT 'en'::character varying,
    stripe_customer_id character varying,
    date_format character varying DEFAULT '%m-%d-%Y'::character varying,
    country character varying DEFAULT 'US'::character varying,
    timezone character varying,
    data_enrichment_enabled boolean DEFAULT false,
    early_access boolean DEFAULT false,
    auto_sync_on_login boolean DEFAULT true NOT NULL
);


--
-- Name: holdings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holdings (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    account_id uuid NOT NULL,
    security_id uuid NOT NULL,
    date date NOT NULL,
    qty numeric(19,4) NOT NULL,
    price numeric(19,4) NOT NULL,
    amount numeric(19,4) NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: impersonation_session_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impersonation_session_logs (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    impersonation_session_id uuid NOT NULL,
    controller character varying,
    action character varying,
    path text,
    method character varying,
    ip_address character varying,
    user_agent text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: impersonation_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impersonation_sessions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    impersonator_id uuid NOT NULL,
    impersonated_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: import_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_mappings (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    type character varying NOT NULL,
    key character varying,
    value character varying,
    create_when_empty boolean DEFAULT true,
    import_id uuid NOT NULL,
    mappable_type character varying,
    mappable_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: import_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_rows (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    import_id uuid NOT NULL,
    account character varying,
    date character varying,
    qty character varying,
    ticker character varying,
    price character varying,
    amount character varying,
    currency character varying,
    name character varying,
    category character varying,
    tags character varying,
    entity_type character varying,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    exchange_operating_mic character varying
);


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    column_mappings jsonb,
    status character varying,
    raw_file_str character varying,
    normalized_csv_str character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    col_sep character varying DEFAULT ','::character varying,
    family_id uuid NOT NULL,
    account_id uuid,
    type character varying NOT NULL,
    date_col_label character varying,
    amount_col_label character varying,
    name_col_label character varying,
    category_col_label character varying,
    tags_col_label character varying,
    account_col_label character varying,
    qty_col_label character varying,
    ticker_col_label character varying,
    price_col_label character varying,
    entity_type_col_label character varying,
    notes_col_label character varying,
    currency_col_label character varying,
    date_format character varying DEFAULT '%m/%d/%Y'::character varying,
    signage_convention character varying DEFAULT 'inflows_positive'::character varying,
    error character varying,
    number_format character varying,
    exchange_operating_mic_col_label character varying,
    amount_type_strategy character varying DEFAULT 'signed_amount'::character varying,
    amount_type_inflow_value character varying
);


--
-- Name: investments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investments (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    email character varying,
    role character varying,
    token character varying,
    family_id uuid NOT NULL,
    inviter_id uuid NOT NULL,
    accepted_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: invite_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite_codes (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    token character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    rate_type character varying,
    interest_rate numeric(10,3),
    term_months integer,
    initial_balance numeric(19,4),
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: merchants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merchants (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    name character varying NOT NULL,
    color character varying,
    family_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    logo_url character varying,
    website_url character varying,
    type character varying NOT NULL,
    source character varying,
    provider_merchant_id character varying
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    chat_id uuid NOT NULL,
    type character varying NOT NULL,
    status character varying DEFAULT 'complete'::character varying NOT NULL,
    content text,
    ai_model character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    debug boolean DEFAULT false,
    provider_id character varying,
    reasoning boolean DEFAULT false
);


--
-- Name: other_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.other_assets (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: other_liabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.other_liabilities (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: plaid_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plaid_accounts (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    plaid_item_id uuid NOT NULL,
    plaid_id character varying NOT NULL,
    plaid_type character varying NOT NULL,
    plaid_subtype character varying,
    current_balance numeric(19,4),
    available_balance numeric(19,4),
    currency character varying NOT NULL,
    name character varying NOT NULL,
    mask character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    raw_transactions_payload jsonb DEFAULT '{}'::jsonb,
    raw_investments_payload jsonb DEFAULT '{}'::jsonb,
    raw_liabilities_payload jsonb DEFAULT '{}'::jsonb
);


--
-- Name: plaid_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plaid_items (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    family_id uuid NOT NULL,
    access_token character varying,
    plaid_id character varying NOT NULL,
    name character varying,
    next_cursor character varying,
    scheduled_for_deletion boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    available_products character varying[] DEFAULT '{}'::character varying[],
    billed_products character varying[] DEFAULT '{}'::character varying[],
    plaid_region character varying DEFAULT 'us'::character varying NOT NULL,
    institution_url character varying,
    institution_id character varying,
    institution_color character varying,
    status character varying DEFAULT 'good'::character varying NOT NULL,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    raw_institution_payload jsonb DEFAULT '{}'::jsonb
);


--
-- Name: properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    year_built integer,
    area_value integer,
    area_unit character varying,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: rejected_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejected_transfers (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    inflow_transaction_id uuid NOT NULL,
    outflow_transaction_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rule_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rule_actions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    rule_id uuid NOT NULL,
    action_type character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rule_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rule_conditions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    rule_id uuid,
    parent_id uuid,
    condition_type character varying NOT NULL,
    operator character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rules (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    family_id uuid NOT NULL,
    resource_type character varying NOT NULL,
    effective_date date,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: securities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.securities (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    ticker character varying NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    country_code character varying,
    exchange_mic character varying,
    exchange_acronym character varying,
    logo_url character varying,
    exchange_operating_mic character varying,
    offline boolean DEFAULT false NOT NULL,
    failed_fetch_at timestamp(6) without time zone,
    failed_fetch_count integer DEFAULT 0 NOT NULL,
    last_health_check_at timestamp(6) without time zone
);


--
-- Name: security_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_prices (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    date date NOT NULL,
    price numeric(19,4) NOT NULL,
    currency character varying DEFAULT 'USD'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    security_id uuid
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    user_id uuid NOT NULL,
    user_agent character varying,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active_impersonator_session_id uuid,
    subscribed_at timestamp(6) without time zone,
    prev_transaction_page_params jsonb DEFAULT '{}'::jsonb,
    data jsonb DEFAULT '{}'::jsonb
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    var character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    family_id uuid NOT NULL,
    status character varying NOT NULL,
    stripe_id character varying,
    amount numeric(19,4),
    currency character varying,
    "interval" character varying,
    current_period_ends_at timestamp(6) without time zone,
    trial_ends_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: syncs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.syncs (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    syncable_type character varying NOT NULL,
    syncable_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying,
    error character varying,
    data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    parent_id uuid,
    pending_at timestamp(6) without time zone,
    syncing_at timestamp(6) without time zone,
    completed_at timestamp(6) without time zone,
    failed_at timestamp(6) without time zone,
    window_start_date date,
    window_end_date date
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    tag_id uuid NOT NULL,
    taggable_type character varying,
    taggable_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    name character varying,
    color character varying DEFAULT '#e99537'::character varying NOT NULL,
    family_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tool_calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_calls (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    message_id uuid NOT NULL,
    provider_id character varying NOT NULL,
    provider_call_id character varying,
    type character varying NOT NULL,
    function_name character varying,
    function_arguments jsonb,
    function_result jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trades (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    security_id uuid NOT NULL,
    qty numeric(19,4),
    price numeric(19,4),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    currency character varying,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    category_id uuid,
    merchant_id uuid,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfers (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    inflow_transaction_id uuid NOT NULL,
    outflow_transaction_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    family_id uuid NOT NULL,
    first_name character varying,
    last_name character varying,
    email character varying,
    password_digest character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    onboarded_at timestamp(6) without time zone,
    unconfirmed_email character varying,
    otp_secret character varying,
    otp_required boolean DEFAULT false NOT NULL,
    otp_backup_codes character varying[] DEFAULT '{}'::character varying[],
    show_sidebar boolean DEFAULT true,
    default_period character varying DEFAULT 'last_30_days'::character varying NOT NULL,
    last_viewed_chat_id uuid,
    show_ai_sidebar boolean DEFAULT true,
    ai_enabled boolean DEFAULT false NOT NULL,
    theme character varying DEFAULT 'system'::character varying,
    rule_prompts_disabled boolean DEFAULT false,
    rule_prompt_dismissed_at timestamp(6) without time zone,
    goals text[] DEFAULT '{}'::text[],
    set_onboarding_preferences_at timestamp(6) without time zone,
    set_onboarding_goals_at timestamp(6) without time zone
);


--
-- Name: valuations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.valuations (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT public.gen_uuid_v7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    year integer,
    mileage_value integer,
    mileage_unit character varying,
    make character varying,
    model character varying,
    locked_attributes jsonb DEFAULT '{}'::jsonb
);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: balances balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_pkey PRIMARY KEY (id);


--
-- Name: budget_categories budget_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_categories
    ADD CONSTRAINT budget_categories_pkey PRIMARY KEY (id);


--
-- Name: budgets budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: chats chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_pkey PRIMARY KEY (id);


--
-- Name: credit_cards credit_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_cards
    ADD CONSTRAINT credit_cards_pkey PRIMARY KEY (id);


--
-- Name: cryptos cryptos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cryptos
    ADD CONSTRAINT cryptos_pkey PRIMARY KEY (id);


--
-- Name: data_enrichments data_enrichments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_enrichments
    ADD CONSTRAINT data_enrichments_pkey PRIMARY KEY (id);


--
-- Name: depositories depositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.depositories
    ADD CONSTRAINT depositories_pkey PRIMARY KEY (id);


--
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: families families_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT families_pkey PRIMARY KEY (id);


--
-- Name: holdings holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_pkey PRIMARY KEY (id);


--
-- Name: impersonation_session_logs impersonation_session_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_session_logs
    ADD CONSTRAINT impersonation_session_logs_pkey PRIMARY KEY (id);


--
-- Name: impersonation_sessions impersonation_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_sessions
    ADD CONSTRAINT impersonation_sessions_pkey PRIMARY KEY (id);


--
-- Name: import_mappings import_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_mappings
    ADD CONSTRAINT import_mappings_pkey PRIMARY KEY (id);


--
-- Name: import_rows import_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_rows
    ADD CONSTRAINT import_rows_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: investments investments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: invite_codes invite_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_codes
    ADD CONSTRAINT invite_codes_pkey PRIMARY KEY (id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: other_assets other_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.other_assets
    ADD CONSTRAINT other_assets_pkey PRIMARY KEY (id);


--
-- Name: other_liabilities other_liabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.other_liabilities
    ADD CONSTRAINT other_liabilities_pkey PRIMARY KEY (id);


--
-- Name: plaid_accounts plaid_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_accounts
    ADD CONSTRAINT plaid_accounts_pkey PRIMARY KEY (id);


--
-- Name: plaid_items plaid_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items
    ADD CONSTRAINT plaid_items_pkey PRIMARY KEY (id);


--
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- Name: rejected_transfers rejected_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_transfers
    ADD CONSTRAINT rejected_transfers_pkey PRIMARY KEY (id);


--
-- Name: rule_actions rule_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_actions
    ADD CONSTRAINT rule_actions_pkey PRIMARY KEY (id);


--
-- Name: rule_conditions rule_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_conditions
    ADD CONSTRAINT rule_conditions_pkey PRIMARY KEY (id);


--
-- Name: rules rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rules
    ADD CONSTRAINT rules_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: securities securities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.securities
    ADD CONSTRAINT securities_pkey PRIMARY KEY (id);


--
-- Name: security_prices security_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_prices
    ADD CONSTRAINT security_prices_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: syncs syncs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.syncs
    ADD CONSTRAINT syncs_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tool_calls tool_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_pkey PRIMARY KEY (id);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: valuations valuations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.valuations
    ADD CONSTRAINT valuations_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: idx_on_account_id_security_id_date_currency_5323e39f8b; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_account_id_security_id_date_currency_5323e39f8b ON public.holdings USING btree (account_id, security_id, date, currency);


--
-- Name: idx_on_enrichable_id_enrichable_type_source_attribu_5be5f63e08; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_enrichable_id_enrichable_type_source_attribu_5be5f63e08 ON public.data_enrichments USING btree (enrichable_id, enrichable_type, source, attribute_name);


--
-- Name: idx_on_inflow_transaction_id_outflow_transaction_id_412f8e7e26; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_inflow_transaction_id_outflow_transaction_id_412f8e7e26 ON public.rejected_transfers USING btree (inflow_transaction_id, outflow_transaction_id);


--
-- Name: idx_on_inflow_transaction_id_outflow_transaction_id_8cd07a28bd; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_inflow_transaction_id_outflow_transaction_id_8cd07a28bd ON public.transfers USING btree (inflow_transaction_id, outflow_transaction_id);


--
-- Name: index_account_balances_on_account_id_date_currency_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_balances_on_account_id_date_currency_unique ON public.balances USING btree (account_id, date, currency);


--
-- Name: index_accounts_on_accountable_id_and_accountable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_accountable_id_and_accountable_type ON public.accounts USING btree (accountable_id, accountable_type);


--
-- Name: index_accounts_on_accountable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_accountable_type ON public.accounts USING btree (accountable_type);


--
-- Name: index_accounts_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_family_id ON public.accounts USING btree (family_id);


--
-- Name: index_accounts_on_family_id_and_accountable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_family_id_and_accountable_type ON public.accounts USING btree (family_id, accountable_type);


--
-- Name: index_accounts_on_family_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_family_id_and_id ON public.accounts USING btree (family_id, id);


--
-- Name: index_accounts_on_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_import_id ON public.accounts USING btree (import_id);


--
-- Name: index_accounts_on_plaid_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_plaid_account_id ON public.accounts USING btree (plaid_account_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_addresses_on_addressable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_addressable ON public.addresses USING btree (addressable_type, addressable_id);


--
-- Name: index_balances_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_balances_on_account_id ON public.balances USING btree (account_id);


--
-- Name: index_budget_categories_on_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_budget_categories_on_budget_id ON public.budget_categories USING btree (budget_id);


--
-- Name: index_budget_categories_on_budget_id_and_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_budget_categories_on_budget_id_and_category_id ON public.budget_categories USING btree (budget_id, category_id);


--
-- Name: index_budget_categories_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_budget_categories_on_category_id ON public.budget_categories USING btree (category_id);


--
-- Name: index_budgets_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_budgets_on_family_id ON public.budgets USING btree (family_id);


--
-- Name: index_budgets_on_family_id_and_start_date_and_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_budgets_on_family_id_and_start_date_and_end_date ON public.budgets USING btree (family_id, start_date, end_date);


--
-- Name: index_categories_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_family_id ON public.categories USING btree (family_id);


--
-- Name: index_chats_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chats_on_user_id ON public.chats USING btree (user_id);


--
-- Name: index_data_enrichments_on_enrichable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_enrichments_on_enrichable ON public.data_enrichments USING btree (enrichable_type, enrichable_id);


--
-- Name: index_entries_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entries_on_account_id ON public.entries USING btree (account_id);


--
-- Name: index_entries_on_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entries_on_import_id ON public.entries USING btree (import_id);


--
-- Name: index_exchange_rates_on_base_converted_date_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_exchange_rates_on_base_converted_date_unique ON public.exchange_rates USING btree (from_currency, to_currency, date);


--
-- Name: index_exchange_rates_on_from_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_rates_on_from_currency ON public.exchange_rates USING btree (from_currency);


--
-- Name: index_exchange_rates_on_to_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_rates_on_to_currency ON public.exchange_rates USING btree (to_currency);


--
-- Name: index_holdings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_holdings_on_account_id ON public.holdings USING btree (account_id);


--
-- Name: index_holdings_on_security_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_holdings_on_security_id ON public.holdings USING btree (security_id);


--
-- Name: index_impersonation_session_logs_on_impersonation_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_session_logs_on_impersonation_session_id ON public.impersonation_session_logs USING btree (impersonation_session_id);


--
-- Name: index_impersonation_sessions_on_impersonated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_sessions_on_impersonated_id ON public.impersonation_sessions USING btree (impersonated_id);


--
-- Name: index_impersonation_sessions_on_impersonator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_sessions_on_impersonator_id ON public.impersonation_sessions USING btree (impersonator_id);


--
-- Name: index_import_mappings_on_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_mappings_on_import_id ON public.import_mappings USING btree (import_id);


--
-- Name: index_import_mappings_on_mappable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_mappings_on_mappable ON public.import_mappings USING btree (mappable_type, mappable_id);


--
-- Name: index_import_rows_on_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_rows_on_import_id ON public.import_rows USING btree (import_id);


--
-- Name: index_imports_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_family_id ON public.imports USING btree (family_id);


--
-- Name: index_invitations_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_email ON public.invitations USING btree (email);


--
-- Name: index_invitations_on_email_and_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invitations_on_email_and_family_id ON public.invitations USING btree (email, family_id);


--
-- Name: index_invitations_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_family_id ON public.invitations USING btree (family_id);


--
-- Name: index_invitations_on_inviter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_inviter_id ON public.invitations USING btree (inviter_id);


--
-- Name: index_invitations_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invitations_on_token ON public.invitations USING btree (token);


--
-- Name: index_invite_codes_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invite_codes_on_token ON public.invite_codes USING btree (token);


--
-- Name: index_merchants_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merchants_on_family_id ON public.merchants USING btree (family_id);


--
-- Name: index_merchants_on_family_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merchants_on_family_id_and_name ON public.merchants USING btree (family_id, name) WHERE ((type)::text = 'FamilyMerchant'::text);


--
-- Name: index_merchants_on_source_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merchants_on_source_and_name ON public.merchants USING btree (source, name) WHERE ((type)::text = 'ProviderMerchant'::text);


--
-- Name: index_merchants_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merchants_on_type ON public.merchants USING btree (type);


--
-- Name: index_messages_on_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_id ON public.messages USING btree (chat_id);


--
-- Name: index_plaid_accounts_on_plaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plaid_accounts_on_plaid_id ON public.plaid_accounts USING btree (plaid_id);


--
-- Name: index_plaid_accounts_on_plaid_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plaid_accounts_on_plaid_item_id ON public.plaid_accounts USING btree (plaid_item_id);


--
-- Name: index_plaid_items_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plaid_items_on_family_id ON public.plaid_items USING btree (family_id);


--
-- Name: index_plaid_items_on_plaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plaid_items_on_plaid_id ON public.plaid_items USING btree (plaid_id);


--
-- Name: index_rejected_transfers_on_inflow_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rejected_transfers_on_inflow_transaction_id ON public.rejected_transfers USING btree (inflow_transaction_id);


--
-- Name: index_rejected_transfers_on_outflow_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rejected_transfers_on_outflow_transaction_id ON public.rejected_transfers USING btree (outflow_transaction_id);


--
-- Name: index_rule_actions_on_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rule_actions_on_rule_id ON public.rule_actions USING btree (rule_id);


--
-- Name: index_rule_conditions_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rule_conditions_on_parent_id ON public.rule_conditions USING btree (parent_id);


--
-- Name: index_rule_conditions_on_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rule_conditions_on_rule_id ON public.rule_conditions USING btree (rule_id);


--
-- Name: index_rules_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rules_on_family_id ON public.rules USING btree (family_id);


--
-- Name: index_securities_on_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_securities_on_country_code ON public.securities USING btree (country_code);


--
-- Name: index_securities_on_exchange_operating_mic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_securities_on_exchange_operating_mic ON public.securities USING btree (exchange_operating_mic);


--
-- Name: index_securities_on_ticker_and_exchange_operating_mic_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_securities_on_ticker_and_exchange_operating_mic_unique ON public.securities USING btree (upper((ticker)::text), COALESCE(upper((exchange_operating_mic)::text), ''::text));


--
-- Name: index_security_prices_on_security_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_security_prices_on_security_id ON public.security_prices USING btree (security_id);


--
-- Name: index_security_prices_on_security_id_and_date_and_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_security_prices_on_security_id_and_date_and_currency ON public.security_prices USING btree (security_id, date, currency);


--
-- Name: index_sessions_on_active_impersonator_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_active_impersonator_session_id ON public.sessions USING btree (active_impersonator_session_id);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_settings_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_var ON public.settings USING btree (var);


--
-- Name: index_subscriptions_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_on_family_id ON public.subscriptions USING btree (family_id);


--
-- Name: index_syncs_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_syncs_on_parent_id ON public.syncs USING btree (parent_id);


--
-- Name: index_syncs_on_syncable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_syncs_on_syncable ON public.syncs USING btree (syncable_type, syncable_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable ON public.taggings USING btree (taggable_type, taggable_id);


--
-- Name: index_tags_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_family_id ON public.tags USING btree (family_id);


--
-- Name: index_tool_calls_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tool_calls_on_message_id ON public.tool_calls USING btree (message_id);


--
-- Name: index_trades_on_security_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_security_id ON public.trades USING btree (security_id);


--
-- Name: index_transactions_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_category_id ON public.transactions USING btree (category_id);


--
-- Name: index_transactions_on_merchant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_merchant_id ON public.transactions USING btree (merchant_id);


--
-- Name: index_transfers_on_inflow_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transfers_on_inflow_transaction_id ON public.transfers USING btree (inflow_transaction_id);


--
-- Name: index_transfers_on_outflow_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transfers_on_outflow_transaction_id ON public.transfers USING btree (outflow_transaction_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_family_id ON public.users USING btree (family_id);


--
-- Name: index_users_on_last_viewed_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_last_viewed_chat_id ON public.users USING btree (last_viewed_chat_id);


--
-- Name: index_users_on_otp_secret; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_otp_secret ON public.users USING btree (otp_secret) WHERE (otp_secret IS NOT NULL);


--
-- Name: rule_conditions fk_rails_092decce7f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_conditions
    ADD CONSTRAINT fk_rails_092decce7f FOREIGN KEY (parent_id) REFERENCES public.rule_conditions(id);


--
-- Name: transactions fk_rails_0ea2ad3927; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_rails_0ea2ad3927 FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: messages fk_rails_0f670de7ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_0f670de7ba FOREIGN KEY (chat_id) REFERENCES public.chats(id);


--
-- Name: import_rows fk_rails_13e503c4a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_rows
    ADD CONSTRAINT fk_rails_13e503c4a1 FOREIGN KEY (import_id) REFERENCES public.imports(id);


--
-- Name: categories fk_rails_22ababf336; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_22ababf336 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: impersonation_sessions fk_rails_2b92af2e4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_sessions
    ADD CONSTRAINT fk_rails_2b92af2e4a FOREIGN KEY (impersonator_id) REFERENCES public.users(id);


--
-- Name: rejected_transfers fk_rails_2da6f89959; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_transfers
    ADD CONSTRAINT fk_rails_2da6f89959 FOREIGN KEY (outflow_transaction_id) REFERENCES public.transactions(id);


--
-- Name: impersonation_session_logs fk_rails_2ea2f2adc5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_session_logs
    ADD CONSTRAINT fk_rails_2ea2f2adc5 FOREIGN KEY (impersonation_session_id) REFERENCES public.impersonation_sessions(id);


--
-- Name: users fk_rails_33a7580ab9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_33a7580ab9 FOREIGN KEY (last_viewed_chat_id) REFERENCES public.chats(id);


--
-- Name: accounts fk_rails_363bf5a48d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_363bf5a48d FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: entries fk_rails_37a3feaeb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT fk_rails_37a3feaeb6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: transactions fk_rails_3e4f7da228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_rails_3e4f7da228 FOREIGN KEY (merchant_id) REFERENCES public.merchants(id);


--
-- Name: invitations fk_rails_466d8d37e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_466d8d37e1 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: rule_conditions fk_rails_5f51cc0bd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_conditions
    ADD CONSTRAINT fk_rails_5f51cc0bd1 FOREIGN KEY (rule_id) REFERENCES public.rules(id);


--
-- Name: sessions fk_rails_738834d772; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_738834d772 FOREIGN KEY (active_impersonator_session_id) REFERENCES public.impersonation_sessions(id);


--
-- Name: invitations fk_rails_7480156672; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_7480156672 FOREIGN KEY (inviter_id) REFERENCES public.users(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: budget_categories fk_rails_83cbbb6bcc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_categories
    ADD CONSTRAINT fk_rails_83cbbb6bcc FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: accounts fk_rails_86697e7a91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_86697e7a91 FOREIGN KEY (import_id) REFERENCES public.imports(id);


--
-- Name: users fk_rails_87dbf420c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_87dbf420c1 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: trades fk_rails_89e7d6c7d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT fk_rails_89e7d6c7d0 FOREIGN KEY (security_id) REFERENCES public.securities(id);


--
-- Name: plaid_accounts fk_rails_8fb63dd78c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_accounts
    ADD CONSTRAINT fk_rails_8fb63dd78c FOREIGN KEY (plaid_item_id) REFERENCES public.plaid_items(id);


--
-- Name: rule_actions fk_rails_933d41413c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_actions
    ADD CONSTRAINT fk_rails_933d41413c FOREIGN KEY (rule_id) REFERENCES public.rules(id);


--
-- Name: balances fk_rails_9452e1f8fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT fk_rails_9452e1f8fd FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: plaid_items fk_rails_9c72cf4f53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items
    ADD CONSTRAINT fk_rails_9c72cf4f53 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: tool_calls fk_rails_9c8daee481; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT fk_rails_9c8daee481 FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: accounts fk_rails_9d788ddfbc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_9d788ddfbc FOREIGN KEY (plaid_account_id) REFERENCES public.plaid_accounts(id);


--
-- Name: transfers fk_rails_9d957b82f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_rails_9d957b82f0 FOREIGN KEY (outflow_transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: budget_categories fk_rails_a928ada795; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_categories
    ADD CONSTRAINT fk_rails_a928ada795 FOREIGN KEY (budget_id) REFERENCES public.budgets(id);


--
-- Name: syncs fk_rails_ac338208d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.syncs
    ADD CONSTRAINT fk_rails_ac338208d1 FOREIGN KEY (parent_id) REFERENCES public.syncs(id);


--
-- Name: transfers fk_rails_b7f6b2cde7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_rails_b7f6b2cde7 FOREIGN KEY (inflow_transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: tags fk_rails_c7b66bad79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_c7b66bad79 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: impersonation_sessions fk_rails_cca4e14dea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_sessions
    ADD CONSTRAINT fk_rails_cca4e14dea FOREIGN KEY (impersonated_id) REFERENCES public.users(id);


--
-- Name: holdings fk_rails_cd86ce9d77; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT fk_rails_cd86ce9d77 FOREIGN KEY (security_id) REFERENCES public.securities(id);


--
-- Name: budgets fk_rails_d298be5805; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT fk_rails_d298be5805 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: subscriptions fk_rails_d8acfbffc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_d8acfbffc8 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: rules fk_rails_e4bc52f9b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rules
    ADD CONSTRAINT fk_rails_e4bc52f9b6 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: chats fk_rails_e555f43151; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT fk_rails_e555f43151 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: merchants fk_rails_ea5781c1b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT fk_rails_ea5781c1b9 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: holdings fk_rails_ef2ad271e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT fk_rails_ef2ad271e6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: entries fk_rails_f8a7316f9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT fk_rails_f8a7316f9a FOREIGN KEY (import_id) REFERENCES public.imports(id);


--
-- Name: security_prices fk_rails_fb42b7e597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_prices
    ADD CONSTRAINT fk_rails_fb42b7e597 FOREIGN KEY (security_id) REFERENCES public.securities(id);


--
-- Name: rejected_transfers fk_rails_fbdaa55382; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_transfers
    ADD CONSTRAINT fk_rails_fbdaa55382 FOREIGN KEY (inflow_transaction_id) REFERENCES public.transactions(id);


--
-- Name: imports fk_rails_fef4f8a5b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT fk_rails_fef4f8a5b1 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20250605020759'),
('20250605015600'),
('20250523131455'),
('20250522201031'),
('20250521112347'),
('20250518181619'),
('20250516180846'),
('20250514214242'),
('20250513122703'),
('20250512171654'),
('20250509182903'),
('20250502164951'),
('20250501172430'),
('20250429021255'),
('20250416235758'),
('20250416235420'),
('20250416235317'),
('20250413141446'),
('20250411140604'),
('20250410144939'),
('20250405210514'),
('20250319212839'),
('20250319145426'),
('20250318212559'),
('20250316122019'),
('20250316103753'),
('20250315191233'),
('20250304200956'),
('20250304140435'),
('20250303141007'),
('20250220200735'),
('20250220153958'),
('20250212213301'),
('20250212163624'),
('20250211161238'),
('20250207194638'),
('20250207014022'),
('20250207011850'),
('20250206204404'),
('20250206151825'),
('20250206141452'),
('20250206003115'),
('20250131171943'),
('20250130214500'),
('20250130191533'),
('20250128203303'),
('20250124224316'),
('20250120210449'),
('20250110012347'),
('20250108200055'),
('20250108182147'),
('20241231140709'),
('20241227142333'),
('20241219174803'),
('20241219151540'),
('20241218132503'),
('20241217141716'),
('20241212141453'),
('20241207002408'),
('20241204235400'),
('20241126211249'),
('20241122183828'),
('20241114164118'),
('20241108150422'),
('20241106193743'),
('20241030222235'),
('20241030151105'),
('20241030121302'),
('20241029234028'),
('20241029184115'),
('20241029125406'),
('20241025182612'),
('20241025174650'),
('20241024142537'),
('20241023195438'),
('20241022221544'),
('20241022192319'),
('20241022170439'),
('20241018201653'),
('20241017204250'),
('20241017162536'),
('20241017162347'),
('20241009214601'),
('20241009132959'),
('20241008122449'),
('20241007211438'),
('20241003163448'),
('20241001181256'),
('20240925112218'),
('20240921170426'),
('20240911143158'),
('20240823125526'),
('20240822180845'),
('20240822174006'),
('20240817144454'),
('20240816071555'),
('20240815190722'),
('20240815125404'),
('20240813170608'),
('20240807153618'),
('20240731191344'),
('20240725163339'),
('20240717113535'),
('20240710184249'),
('20240710184048'),
('20240710182728'),
('20240710182529'),
('20240709152243'),
('20240709113715'),
('20240709113714'),
('20240709113713'),
('20240707130331'),
('20240706151026'),
('20240628104551'),
('20240624164119'),
('20240624161153'),
('20240624160611'),
('20240621212528'),
('20240620221801'),
('20240620125026'),
('20240620122201'),
('20240620114307'),
('20240619125949'),
('20240614121110'),
('20240614120946'),
('20240612164944'),
('20240612164751'),
('20240524203959'),
('20240522151453'),
('20240522133147'),
('20240520074309'),
('20240502205006'),
('20240430111641'),
('20240426191312'),
('20240426162500'),
('20240425000110'),
('20240411102931'),
('20240410183531'),
('20240404112829'),
('20240403192649'),
('20240401213443'),
('20240325064211'),
('20240319154732'),
('20240313203622'),
('20240313141813'),
('20240309180636'),
('20240308214956'),
('20240308121431'),
('20240307082827'),
('20240306193345'),
('20240302145715'),
('20240227142457'),
('20240223162105'),
('20240222144849'),
('20240221004818'),
('20240215201527'),
('20240212150110'),
('20240210155058'),
('20240209200924'),
('20240209200519'),
('20240209174912'),
('20240209153232'),
('20240206031739'),
('20240203050018'),
('20240203030754'),
('20240202230325'),
('20240202192333'),
('20240202192327'),
('20240202192319'),
('20240202192312'),
('20240202192238'),
('20240202192231'),
('20240202192214'),
('20240202191746'),
('20240202191425'),
('20240202015428'),
('20240201184212'),
('20240201184038'),
('20240201183314');


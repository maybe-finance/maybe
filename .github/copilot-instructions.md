# GitHub Copilot Instructions for Maybe

## Project Overview

Maybe is a personal finance application built with Ruby on Rails that helps users manage their financial accounts, transactions, and investments. The app supports both managed hosting and self-hosting modes.

## Critical Development Rules

### Authentication Context
**CRITICAL**: Always use `Current.user` and `Current.family` instead of Rails' `current_user`/`current_family` helpers.

### Prohibited Actions
- Do NOT run `rails server`, `touch tmp/restart.txt`, or `rails credentials` in responses
- Do NOT automatically run migrations
- Ignore i18n methods and files - hardcode strings in English for development speed

### Code Review Requirements
Before generating any code:
1. Read project conventions for "how" to write code
2. Understand the domain model architecture 
3. Follow UI/UX design guidelines for frontend code

## Core Architecture Patterns

### App Modes
The Maybe app runs in two distinct modes:
- **Managed**: The Maybe team operates servers (`Rails.application.config.app_mode.managed?`)
- **Self Hosted**: Users host via Docker Compose (`Rails.application.config.app_mode.self_hosted?`)

### Domain Model Hierarchy
- **Family** → **Users** (admin/member roles) 
- **Family** → **Accounts** (checking, savings, credit cards, investments, crypto, loans, properties)
- **Account** → **Entries** → **Entryables** (Transaction, Valuation, Trade)
- **Transaction** → **Category**, **Tags**, **Merchant** (optional associations)

Key relationship: `Family#accounts.transactions.entries` represents the financial ledger.

### Account Types & Polymorphic Design
Accounts use Rails `delegated_type` with `accountable` field pointing to:
- **Asset accountables**: `Depository`, `Investment`, `Crypto`, `Property`, `Vehicle`, `OtherAsset`
- **Liability accountables**: `CreditCard`, `Loan`, `OtherLiability`

Example: `account.accountable` returns the specific accountable instance (e.g., `CreditCard` with APR, credit limit).

### Entry System (Event Sourcing)
All account modifications go through `Entry` (delegated type):
- **Transaction**: Income/expense entries that modify account balance by `amount`
- **Valuation**: Absolute account value on a date ("account is worth $5,000 today")
- **Trade**: Buy/sell for investment accounts with `qty` and `price`

**Amount Semantics**: Negative = inflow to account, Positive = outflow from account

### Authentication Context
**CRITICAL**: Always use `Current.user` and `Current.family` instead of Rails' `current_user`/`current_family` helpers.

### Transaction Types & Transfers
Transactions have `kind` enum: `standard`, `funds_movement`, `cc_payment`, `loan_payment`, `one_time`
- `Transfer` model links inflow/outflow transactions between accounts
- Kind automatically set based on account type: loans→`loan_payment`, credit cards→`cc_payment`, others→`funds_movement`

### Sync System Architecture
The app implements background sync for all data updates via `Syncable` concern:
- **Account Sync**: Auto-matches transfers, calculates daily balances, enriches transaction data
- **Plaid Item Sync**: ETL from Plaid API → `PlaidAccount` → internal `Account`/`Entry` models
- **Family Sync**: Daily orchestrator that syncs all family accounts and Plaid items

Every sync creates a `Sync` record for audit trail and error tracking.

### Provider System for External Data
Uses registry pattern for swappable data providers:
- **Concept providers**: Generic data (exchange rates, security prices) with interface
- **One-off providers**: Specific implementations without abstraction
- **"Provided" concerns**: Domain model convenience methods for provider access

Example: `ExchangeRate.find_or_fetch_rate(from: "USD", to: "EUR")` uses configured provider.

### Convention 1: Minimize dependencies, vanilla Rails is plenty

Dependencies are a natural part of building software, but we aim to minimize them when possible to keep this open-source codebase easy to understand, maintain, and contribute to.

- Push Rails to its limits before adding new dependencies
- When a new dependency is added, there must be a strong technical or business reason to add it
- When adding dependencies, you should favor old and reliable over new and flashy 

### Convention 2: Leverage POROs and concerns over "service objects"

This codebase adopts a "skinny controller, fat models" convention.  Furthermore, we put almost _everything_ directly in the `app/models/` folder and avoid separate folders for business logic such as `app/services/`.

- Organize large pieces of business logic into Rails concerns and POROs (Plain ole' Ruby Objects)
- While a Rails concern _may_ offer shared functionality (i.e. "duck types"), it can also be a "one-off" concern that is only included in one place for better organization and readability.
- When concerns are used for code organization, they should be organized around the "traits" of a model; not for simply moving code to another spot in the codebase.
- When possible, models should answer questions about themselves—for example, we might have a method, `account.balance_series` that returns a time-series of the account's most recent balances.  We prefer this over something more service-like such as `AccountSeries.new(account).call`.

### Convention 3: Leverage Hotwire, write semantic HTML, CSS, and JS, prefer server-side solutions

- Native HTML is always preferred over JS-based components
  - Example 1: Use `<dialog>` element for modals instead of creating a custom component
  - Example 2: Use `<details><summary>...</summary></details>` for disclosures rather than custom components
- Leverage Turbo frames to break up the page over JS-driven client-side solutions
  - Example 1: A good example of turbo frame usage is in [application.html.erb](mdc:app/views/layouts/application.html.erb) where we load [chats_controller.rb](mdc:app/controllers/chats_controller.rb) actions in a turbo frame in the global layout
- Leverage query params in the URL for state over local storage and sessions.  If absolutely necessary, utilize the DB for persistent state.
- Use Turbo streams to enhance functionality, but do not solely depend on it
- Format currencies, numbers, dates, and other values server-side, then pass to Stimulus controllers for display only
- Keep client-side code for where it truly shines.  For example, @bulk_select_controller.js is a case where server-side solutions would degrade the user experience significantly.  When bulk-selecting entries, client-side solutions are the way to go and Stimulus provides the right toolset to achieve this.
- Always use the `icon` helper in [application_helper.rb](mdc:app/helpers/application_helper.rb) for icons.  NEVER use `lucide_icon` helper directly.

The Hotwire suite (Turbo/Stimulus) works very well with these native elements and we optimize for this.

### Convention 4: Optimize for simplicitly and clarity

All code should maximize readability and simplicity.

- Prioritize good OOP domain design over performance
- Only focus on performance for critical and global areas of the codebase; otherwise, don't sweat the small stuff.
  - Example 1: be mindful of loading large data payloads in global layouts
  - Example 2: Avoid N+1 queries

### Convention 5: Use ActiveRecord for complex validations, DB for simple ones, keep business logic out of DB

- Enforce `null` checks, unique indexes, and other simple validations in the DB
- ActiveRecord validations _may_ mirror the DB level ones, but not 100% necessary.  These are for convenience when error handling in forms.  Always prefer client-side form validation when possible.
- Complex validations and business logic should remain in ActiveRecord

### Frontend Architecture (Hotwire-first)
- **Native HTML over JS**: Use `<dialog>`, `<details>` instead of custom components
- **Turbo Frames**: Break up pages server-side (see chat integration in `application.html.erb`)
- **Stimulus**: Declarative actions only - ERB declares `data-action="click->controller#method"`
- **Component vs Partial**: Use ViewComponents for reusable/complex UI, partials for static content

### TailwindCSS Design System
- **Always use functional tokens**: `text-primary` not `text-white`, `bg-container` not `bg-white`
- **Reference design system**: Check `app/assets/tailwind/maybe-design-system.css` for available tokens
- **Never modify**: Don't create new styles in design system files without permission
- **Semantic HTML**: Always generate proper semantic markup

### Essential Helper Patterns
```ruby
# Icons - ALWAYS use this helper, never lucide_icon directly
icon("credit-card", class: "w-4 h-4")

# Money formatting - server-side formatting preferred
account.balance_money.format
```

## Critical Workflows

### Development Commands
```bash
# Start development server
bin/dev

# Run tests before PRs (REQUIRED)
bin/rails test
bin/rubocop -f github -a
bin/brakeman --no-pager

# Database operations
bin/rails db:prepare
rake demo_data:default  # Load demo data
```

### Account & Transaction Creation
- **Account creation**: Use `Account.create_and_sync` which handles opening balance and sync
- **Transaction creation**: Always call `entry.sync_account_later` after save
- **Transfer creation**: Use `Transfer::Creator` service for proper setup

### Sync System Architecture
- **Plaid Integration**: `PlaidItem` → `PlaidAccount` → background jobs sync data
- **Manual Sync**: `account.sync_later` queues Sidekiq job for balance/valuation updates
- **Import System**: CSV imports via `Import` → `Import::Row` → `Import::Mapping` classes

## Testing Approach

### Minitest + Fixtures (No RSpec/FactoryBot)
- **Minimal fixtures**: 2-3 base cases per model maximum
- **Test helpers**: Use `EntriesTestHelper.create_transaction` for transaction setup
- **Focus on critical paths**: Business logic, not ActiveRecord functionality
- **System tests sparingly**: Only for complex user workflows

### Test Example Pattern
```ruby
# GOOD - Testing business logic
test "transfers sum to zero" do
  transfer = Transfer::Creator.new(
    family: @family,
    source_account_id: @checking.id,
    destination_account_id: @savings.id,
    amount: 100,
    date: Date.current
  ).create
  
  assert_equal 0, transfer.inflow_transaction.entry.amount + transfer.outflow_transaction.entry.amount
end
```

## Integration Points

### External Services
- **Plaid**: Bank data sync via `PlaidAccount::Processor`
- **Synth**: Market data for multi-currency support (`Rails.application.config.synth_api_key`)
- **OpenAI**: AI chat and auto-categorization features
- **Sidekiq**: Background job processing for syncs and imports

### API Architecture
- **Internal API**: Controllers serve JSON via Turbo for SPA interactions
- **External API**: `/api/v1/` with Doorkeeper OAuth + API key auth
- **Rate limiting**: Rack::Attack with configurable limits per API key

## File Structure Patterns

### Components Structure
- `app/components/UI/` - Page-level components (`UI::AccountPage`)
- `app/components/DS/` - Design system components (`DS::Button`)
- Global controllers: `app/javascript/controllers/`
- Component controllers: `app/components/[component]/controller.js`

### Model Organization Examples
- Core models: `app/models/{account,family,transaction}.rb`
- Business logic: `app/models/balance_sheet/account_totals.rb`
- Services: `app/models/transfer/creator.rb`, `app/models/account/syncer.rb`
- Concerns: `app/models/concerns/{monetizable,syncable,chartable}.rb`

## Key Performance Considerations

- **Family cache keys**: Use `family.build_cache_key(key, invalidate_on_data_updates: true)` 
- **Avoid N+1**: Especially in account/transaction lists and balance calculations
- **Background processing**: Sync operations always run via Sidekiq to avoid blocking UI

## App Mode Awareness

Check `Rails.application.config.app_mode.self_hosted?` vs `.managed?` for feature toggles between self-hosted and managed deployments.

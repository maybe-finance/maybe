---
description: This rule explains the system architecture and data flow of the Rails app
globs: *
alwaysApply: true
---

This file outlines how the codebase is structured and how data flows through the app.

This is a personal finance application built in Ruby on Rails.  The primary domain entities for this app are outlined below.  For an authoritative overview of the relationships, [schema.rb](mdc:db/schema.rb) is the source of truth.

## App Modes

The Maybe app runs in two distinct "modes", dictated by `Rails.application.config.app_mode`, which can be `managed` or `self_hosted`.

- "Managed" - in managed mode, the Maybe team operates and manages servers for users
- "Self Hosted" - in self hosted mode, users host the Maybe app on their own infrastructure, typically through Docker Compose.  We have an example [docker-compose.example.yml](mdc:docker-compose.example.yml) file that runs [Dockerfile](mdc:Dockerfile) for this mode.

## Families and Users

- `Family` - all Stripe subscriptions, financial accounts, and the majority of preferences are stored at the [family.rb](mdc:app/models/family.rb) level.
- `User` - all [session.rb](mdc:app/models/session.rb) happen at the [user.rb](mdc:app/models/user.rb) level.  A user belongs to a `Family` and can either be an `admin` or a `member`.  Typically, a `Family` has a single admin, or "head of household" that manages finances while there will be several `member` users who can see the family's finances from varying perspectives.

## Currency Preference

Each `Family` selects a currency preference.  This becomes the "main" currency in which all records are "normalized" to via [exchange_rate.rb](mdc:app/models/exchange_rate.rb) records so that the Maybe app can calculate metrics, historical graphs, and other insights in a single family currency.

## Accounts

The center of the app's domain is the [account.rb](mdc:app/models/account.rb).  This represents a single financial account that has a `balance` and `currency`.  For example, an `Account` could be "Chase Checking", which is a single financial account at Chase Bank.  A user could have multiple accounts at a single institution (i.e. "Chase Checking", "Chase Credit Card", "Chase Savings") or an account could be a standalone account, such as "My Home" (a primary residence).

### Accountables

In the app, [account.rb](mdc:app/models/account.rb) is a Rails "delegated type" with the following subtypes (separate DB tables).  Each account has a `classification` or either `asset` or `liability`.  While the types are a flat hierarchy, below, they have been organized by their classification:

- Asset accountables
  - [depository.rb](mdc:app/models/depository.rb) - a typical "bank account" such as a savings or checking account
  - [investment.rb](mdc:app/models/investment.rb) - an account that has "holdings" such as a brokerage, 401k, etc.
  - [crypto.rb](mdc:app/models/crypto.rb) - an account that tracks the value of one or more crypto holdings
  - [property.rb](mdc:app/models/property.rb) - an account that tracks the value of a physical property such as a house or rental property
  - [vehicle.rb](mdc:app/models/vehicle.rb) - an account that tracks the value of a vehicle
  - [other_asset.rb](mdc:app/models/other_asset.rb) - an asset that cannot be classified by the other account types.  For example, "jewelry".
- Liability accountables
  - [credit_card.rb](mdc:app/models/credit_card.rb) - an account that tracks the debt owed on a credit card
  - [loan.rb](mdc:app/models/loan.rb) - an account that tracks the debt owed on a loan (i.e. mortgage, student loan)
  - [other_liability.rb](mdc:app/models/other_liability.rb) - a liability that cannot be classified by the other account types.  For example, "IOU to a friend"

### Account Balances

An account [balance.rb](mdc:app/models/account/balance.rb) represents a single balance value for an account on a specific `date`.  A series of balance records is generated daily for each account and is how we show a user's historical balance graph.  

- For simple accounts like a "Checking Account", the balance represents the amount of cash in the account for a date.  
- For a more complex account like "Investment Brokerage", the `balance` represents the combination of the "cash balance" + "holdings value".  Each accountable type has different components that make up the "balance", but in all cases, the "balance" represents "How much the account is worth" (when `classification` is `asset`) or "How much is owed on the account" (when `classification` is `liability`)

All balances are calculated daily by [balance_calculator.rb](mdc:app/models/account/balance_calculator.rb).

### Account Holdings

An account [holding.rb](mdc:app/models/holding.rb) applies to [investment.rb](mdc:app/models/investment.rb) type accounts and represents a `qty` of a certain [security.rb](mdc:app/models/security.rb) at a specific `price` on a specific `date`.

For investment accounts with holdings, [base_calculator.rb](mdc:app/models/holding/base_calculator.rb) is used to calculate the daily historical holding quantities and prices, which are then rolled up into a final "Balance" for the account in [base_calculator.rb](mdc:app/models/account/balance/base_calculator.rb).

### Account Entries

An account [entry.rb](mdc:app/models/entry.rb) is also a Rails "delegated type".  `Entry` represents any record that _modifies_ an `Account` [balance.rb](mdc:app/models/account/balance.rb) and/or [holding.rb](mdc:app/models/holding.rb).  Therefore, every entry must have a `date`, `amount`, and `currency`.

The `amount` of an [entry.rb](mdc:app/models/entry.rb) is a signed value.  A _negative_ amount is an "inflow" of money to that account.  A _positive_ value is an "outflow" of money from that account.  For example:

- A negative amount for a credit card account represents a "payment" to that account, which _reduces_ its balance (since it is a `liability`)
- A negative amount for a checking account represents an "income" to that account, which _increases_ its balance (since it is an `asset`)
- A negative amount for an investment/brokerage trade represents a "sell" transaction, which _increases_ the cash balance of the account 

There are 3 entry types, defined as [entryable.rb](mdc:app/models/entryable.rb) records: 

- `Valuation` - an account [valuation.rb](mdc:app/models/valuation.rb) is an entry that says, "here is the value of this account on this date".  It is an absolute measure of an account value / debt.  If there is an `Valuation` of 5,000 for today's date, that means that the account balance will be 5,000 today.
- `Transaction` - an account [transaction.rb](mdc:app/models/transaction.rb) is an entry that alters the account balance by the `amount`.  This is the most common type of entry and can be thought of as an "income" or "expense".  
- `Trade` - an account [trade.rb](mdc:app/models/trade.rb) is an entry that only applies to an investment account.  This represents a "buy" or "sell" of a holding and has a `qty` and `price`.

### Account Transfers

A [transfer.rb](mdc:app/models/transfer.rb) represents a movement of money between two accounts.  A transfer has an inflow [transaction.rb](mdc:app/models/transaction.rb) and an outflow [transaction.rb](mdc:app/models/transaction.rb).  The Maybe system auto-matches transfers based on the following criteria:

- Must be from different accounts
- Must be within 4 days of each other
- Must be the same currency
- Must be opposite values

There are two primary forms of a transfer:

- Regular transfer - a normal movement of money between two accounts.  For example, "Transfer $500 from Checking account to Brokerage account". 
- Debt payment - a special form of transfer where the _receiver_ of funds is a [loan.rb](mdc:app/models/loan.rb) type account.  

Regular transfers are typically _excluded_ from income and expense calculations while a debt payment is considered an "expense".

## Plaid Items

A [plaid_item.rb](mdc:app/models/plaid_item.rb) represents a "connection" maintained by our external data provider, Plaid in the "hosted" mode of the app.  An "Item" has 1 or more [plaid_account.rb](mdc:app/models/plaid_account.rb) records, which are each associated 1:1 with an internal Maybe [account.rb](mdc:app/models/account.rb).

All relevant metadata about the item and its underlying accounts are stored on [plaid_item.rb](mdc:app/models/plaid_item.rb) and [plaid_account.rb](mdc:app/models/plaid_account.rb), while the "normalized" data is then stored on internal Maybe domain models.

## "Syncs"

The Maybe app has the concept of a [syncable.rb](mdc:app/models/concerns/syncable.rb), which represents any model which can have its data "synced" in the background.  "Syncables" include:

- `Account` - an account "sync" will sync account holdings, balances, and enhance transaction metadata
- `PlaidItem` - a Plaid Item "sync" fetches data from Plaid APIs, normalizes that data, stores it on internal Maybe models, and then finally performs an "Account sync" for each of the underlying accounts created from the Plaid Item.
- `Family` - a Family "sync" loops through the family's Plaid Items and individual Accounts and "syncs" each of them.  A family is synced once per day, automatically through [auto_sync.rb](mdc:app/controllers/concerns/auto_sync.rb).

Each "sync" creates a [sync.rb](mdc:app/models/sync.rb) record in the database, which keeps track of the status of the sync, any errors that it encounters, and acts as an "audit table" for synced data.

Below are brief descriptions of each type of sync in more detail.

### Account Syncs

The most important type of sync is the account sync.  It is orchestrated by the account's `sync_data` method, which performs a few important tasks:

- Auto-matches transfer records for the account
- Calculates daily [balance.rb](mdc:app/models/account/balance.rb) records for the account from `account.start_date` to `Date.current` using [base_calculator.rb](mdc:app/models/account/balance/base_calculator.rb)
  - Balances are dependent on the calculation of [holding.rb](mdc:app/models/holding.rb), which uses [base_calculator.rb](mdc:app/models/account/holding/base_calculator.rb) 
- Enriches transaction data if enabled by user

An account sync happens every time an [entry.rb](mdc:app/models/entry.rb) is updated.

### Plaid Item Syncs

A Plaid Item sync is an ETL (extract, transform, load) operation:

1. [plaid_item.rb](mdc:app/models/plaid_item.rb) fetches data from the external Plaid API
2. [plaid_item.rb](mdc:app/models/plaid_item.rb) creates and loads this data to [plaid_account.rb](mdc:app/models/plaid_account.rb) records
3. [plaid_item.rb](mdc:app/models/plaid_item.rb) and [plaid_account.rb](mdc:app/models/plaid_account.rb) transform and load data to [account.rb](mdc:app/models/account.rb) and [entry.rb](mdc:app/models/entry.rb), the internal Maybe representations of the data.

### Family Syncs

A family sync happens once daily via [auto_sync.rb](mdc:app/controllers/concerns/auto_sync.rb).  A family sync is an "orchestrator" of Account and Plaid Item syncs.

## Data Providers

The Maybe app utilizes several 3rd party data services to calculate historical account balances, enrich data, and more.  Since the app can be run in both "hosted" and "self hosted" mode, this means that data providers are _optional_ for self hosted users and must be configured.

Because of this optionality, data providers must be configured at _runtime_ through [registry.rb](mdc:app/models/provider/registry.rb) utilizing [setting.rb](mdc:app/models/setting.rb) for runtime parameters like API keys:

There are two types of 3rd party data in the Maybe app:

1. "Concept" data
2. One-off data

### "Concept" data

Since the app is self hostable, users may prefer using different providers for generic data like exchange rates and security prices.  When data is generic enough where we can easily swap out different providers, we call it a data "concept".

Each "concept" has an interface defined in the `app/models/provider/concepts` directory.

```
app/models/
  exchange_rate/
    provided.rb # <- Responsible for selecting the concept provider from the registry
  provider.rb # <- Base provider class
  provider/
    registry.rb <- Defines available providers by concept
    concepts/
      exchange_rate.rb <- defines the interface required for the exchange rate concept
    synth.rb # <- Concrete provider implementation
```

### One-off data

For data that does not fit neatly into a "concept", an interface is not required and the concrete provider may implement ad-hoc methods called directly in code.  For example, the [synth.rb](mdc:app/models/provider/synth.rb) provider has a `usage` method that is only applicable to this specific provider.  This should be called directly without any abstractions:

```rb
class SomeModel < Application
  def synth_usage
    Provider::Registry.get_provider(:synth)&.usage
  end
end
```

## "Provided" Concerns

In general, domain models should not be calling [registry.rb](mdc:app/models/provider/registry.rb) directly.  When 3rd party data is required for a domain model, we use the `Provided` concern within that model's namespace.  This concern is primarily responsible for:

- Choosing the provider to use for this "concept"
- Providing convenience methods on the model for accessing data

For example, [exchange_rate.rb](mdc:app/models/exchange_rate.rb) has a [provided.rb](mdc:app/models/exchange_rate/provided.rb) concern with the following convenience methods:

```rb
module ExchangeRate::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      registry = Provider::Registry.for_concept(:exchange_rates)
      registry.get_provider(:synth)
    end

    def find_or_fetch_rate(from:, to:, date: Date.current, cache: true)
      # Implementation 
    end

    def sync_provider_rates(from:, to:, start_date:, end_date: Date.current)
      # Implementation 
    end
  end
end
```

This exposes a generic access pattern where the caller does not care _which_ provider has been chosen for the concept of exchange rates and can get a predictable response:

```rb
def access_patterns_example
  # Call exchange rate provider directly
  ExchangeRate.provider.fetch_exchange_rate(from: "USD", to: "CAD", date: Date.current)

  # Call convenience method
  ExchangeRate.sync_provider_rates(from: "USD", to: "CAD", start_date: 2.days.ago.to_date)
end
```

## Concrete provider implementations

Each 3rd party data provider should have a class under the `Provider::` namespace that inherits from `Provider` and returns `with_provider_response`, which will return a `Provider::ProviderResponse` object:

```rb
class ConcreteProvider < Provider
  def fetch_some_data
    with_provider_response do
      ExampleData.new(
        example: "data"
      )
    end
  end
end
```

The `with_provider_response` automatically catches provider errors, so concrete provider classes should raise when valid data is not possible:

```rb
class ConcreteProvider < Provider
  def fetch_some_data
    with_provider_response do
      data = nil

      # Raise an error if data cannot be returned
      raise ProviderError.new("Could not find the data you need") if data.nil?

      data
    end
  end
end
```

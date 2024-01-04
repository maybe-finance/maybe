# Maybe: Your personal financial assistant

Maybe aims to be a personal financial assistant, helping you manage your money, make investments and grow your wealth.

We're aiming to be hyper-transparent, fully open-source and community-driven.

This codebase is currently in a very early stage of development, and is not product-ready yet. It has a lot of "leftovers" from an early prototype (which was not open-source).

## Codebase

The codebase is vanilla [Rails](https://rubyonrails.org/), [Sidekiq](https://sidekiq.org/) w/ [Redis](https://redis.io/), [Puma](http://puma.io/), and [Postgres](https://www.postgresql.org/). Quite a simple setup.

## Setup

You'll need:

- ruby >3 (specific version is in `Gemfile`)
- postgresql (if using stock `config/database.yml`)

```shell
cd maybe
bundle install
rails db:setup
```

You can then run the rails web server:

```shell
bin/dev
```

And visit [http://localhost:5000](http://localhost:5000)

### Read-only user setup

After you've set up the initial database, you need to create a read-only user for the AI to use.

Eventually we should build a setup script to help with this, but for now you need to manually run the following SQL in your `maybe_ai_development` database:

```sql
CREATE ROLE ai_user WITH LOGIN PASSWORD 'YOUR_UNIQUE_PASSWORD';

GRANT SELECT ON balances TO ai_user;
GRANT SELECT ON accounts TO ai_user;
GRANT SELECT ON connections TO ai_user;
GRANT SELECT ON conversations TO ai_user;
GRANT SELECT ON holdings TO ai_user;
GRANT SELECT ON investment_transactions TO ai_user;
GRANT SELECT ON messages TO ai_user;
GRANT SELECT ON metrics TO ai_user;
GRANT SELECT ON transactions TO ai_user;
```

Then, in your `.env` file you need to set the `READONLY_DATABASE_URL` to:

```
postgres://ai_user:YOUR_UNIQUE_PASSWORD@localhost/maybe_ai_development
```

## External Services

Currently the app relies on a few external services:

- [Plaid](https://plaid.com) for bank account linking
- [Ntropy](https://www.ntropy.com) for transaction enrichment
- [OpenAI](https://openai.com) for natural language processing
- [TwelveData](https://twelvedata.com) for stock market data
- [Polygon](https://polygon.io) for stock market data
- [ScrapingBee](https://www.scrapingbee.com) for web scraping

The goal is to eventually move away from these services and bring everything in-house as much as possible, but for the app to fully function, you'll need API keys from those services.

You can find the necessary API keys in `.env.example`, which you can copy to `.env` and fill in the values.

## Contributing

It's still very early days for this so your mileage will vary here and lots of things will break.

But almost any contribution will be beneficial at this point. Check the [current Issues](https://github.com/maybe-finance/maybe/issues) to see where you can jump in!

If you've got an improvement, just send in a pull request!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

If you've got feature ideas, simply [open a new issues](https://github.com/maybe-finance/maybe/issues/new)!

## Community

- Join the conversation in our [Discord](https://discord.gg/rDZFvtGcxx)
- Follow us on [Twitter](https://twitter.com/maybe)

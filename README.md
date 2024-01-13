![](https://github.com/maybe-finance/maybe/assets/35243/79d97b31-7fad-4031-9e83-5005bc1d7fd0)

# Maybe: Open-source personal finance app

<b>Get involved: [Discord](https://link.maybe.co/discord) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

🚨 NOTE: This is the original React app of the previously-defunct personal finance app, Maybe. This original version used many external services (Plaid, Finicity, Auth0, etc) and getting it to fully function will be a decent amount of work.

There's a LOT of work to do to get this functioning, but it should be feasible.

## Backstory

We spent the better part of 2021/2022 building a personal finance + wealth management app called Maybe. Very full-featured, including an "Ask an Advisor" feature which connected users with an actual CFP/CFA to help them with their finances (all included in your subscription).

The business end of things didn't work out and so we shut things down mid-2023.

We spend the better part of $1,000,000 building the app (employees + contractors, data providers/services, infrastructure, etc).

We're now reviving the product as a fully open-source project. The goal is to let you run the app yourself, for free, and use it to manage your own finances and eventually offer a hosted version of the app for a small monthly fee.

## End goal

Ultimately we want to rebuild this so that you can self-host, but we also have plans to offer a hosted version for a fee. That means some decisions will be made that don't explicitly make sense for self-hosted but _do_ support the goal of us offering a for-pay hosted version.

## Features

As a personal finance + wealth management app, Maybe has a lot of features. Here's a brief overview of some of the main ones...

-   Net worth tracking
-   Financial account syncing
-   Investment benchmarking
-   Investment portfolio allocation
-   Debt insights
-   Retirement forecasting + planning
-   Investment return simulation
-   Manual account/investment tracking

And dozens upon dozens of smaller features.

## Building the app

This is the current state of building the app. You'll hit errors, which we're working to resolve (and certainly welcome PRs to help with that).

You'll need Docker installed to run the app locally.

```
cp .env.example .env
yarn install
yarn run dev:services
yarn prisma:migrate:dev
yarn prisma:seed
yarn dev
```

## High-priority issues

The biggest focus at the moment is on getting the app functional without some previously key external services (namely Auth0, Plaid and Finicity).

You can view the current [high-priority issues here](https://github.com/maybe-finance/maybe/issues?q=is:issue+is:open+label:%22high+priority%22). Those are the most impactful issues to tackle first.

## External data

To pull market data in (for investments), you'll need a Polygon.io API key. You can get one for free [here](https://polygon.io/) and then add it to your `.env` file (`NX_POLYGON_API_KEY`).

## Tech stack

-   Next.js
-   Tailwind
-   Node.js
-   Express
-   Postgres (w/ Timescale)

## Relevant reading

-   [Learn about how the app is organized as a monorepo](https://github.com/maybe-finance/maybe/wiki/Monorepo-File-Structure-Overview)
-   [Reference past Auth0 implementation as we work to replace it](https://github.com/maybe-finance/maybe/wiki/Auth0)
-   [Data model assumptions and calculations](https://github.com/maybe-finance/maybe/wiki/Data-model-assumptions-and-calculations)
-   [Handling money](https://github.com/maybe-finance/maybe/wiki/Handling-Money)
-   [REST API](https://github.com/maybe-finance/maybe/wiki/REST-API)

## Credits

The original app was built by [Zach Gollwitzer](https://twitter.com/zg_dev), [Nick Arciero](https://www.narciero.com/) and [Tim Wilson](https://twitter.com/actualTimWilson), with design work by [Justin Farrugia](https://twitter.com/justinmfarrugia). The app is currently maintained by [Josh Pigford](https://twitter.com/Shpigford).

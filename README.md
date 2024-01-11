![](https://github.com/maybe-finance/maybe/assets/35243/79d97b31-7fad-4031-9e83-5005bc1d7fd0)

# Maybe: Open-source personal finance app

<b>Get involved: [Discord](https://link.maybe.co/discord) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

🚨 NOTE: This is the original React app of the previously-defunct personal finance app, Maybe. This original version used many external services (Plaid, Finicity, Auth0, etc) and getting it to fully function will be a decent amount of work.

There's a LOT of work to do to get this functioning, but it should be feasible.

## Features

As a personal finance + wealth management app, Maybe has a lot of features. Here's a quick overview of some of the main ones...

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

## Tech stack

-   Next.js
-   Tailwind
-   Node.js
-   Express
-   Postgres (w/ Timescale)

## Relevant reading

-   [Learn about how the app is organized as a monorepo](https://github.com/maybe-finance/maybe/wiki/Monorepo-File-Structure-Overview)
-   [Reference past Auto0 implementation as we work to replace it](https://github.com/maybe-finance/maybe/wiki/Auth0)
-   [Data model assumptions and calculations](https://github.com/maybe-finance/maybe/wiki/Data-model-assumptions-and-calculations)
-   [Handling money](https://github.com/maybe-finance/maybe/wiki/Handling-Money)
-   [REST API](https://github.com/maybe-finance/maybe/wiki/REST-API)

## Credits

The original app was built by [Zach Gollwitzer](https://twitter.com/zg_dev), [Nick Arciero](https://www.narciero.com/) and [Tim Wilson](https://twitter.com/actualTimWilson), with design work by [Justin Farrugia](https://twitter.com/justinmfarrugia). The app is currently maintained by [Josh Pigford](https://twitter.com/Shpigford).

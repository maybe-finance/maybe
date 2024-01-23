![](https://github.com/maybe-finance/maybe/assets/35243/79d97b31-7fad-4031-9e83-5005bc1d7fd0)

# Maybe: Open-source personal finance app

<b>Get involved: [Discord](https://link.maybe.co/discord) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

## Backstory

We spent the better part of 2021/2022 building a personal finance + wealth management app called, Maybe. Very full-featured, including an "Ask an Advisor" feature which connected users with an actual CFP/CFA to help them with their finances (all included in your subscription).

The business end of things didn't work out, and so we shut things down mid-2023.

We spent the better part of $1,000,000 building the app (employees + contractors, data providers/services, infrastructure, etc.).

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

## Getting started

This is the current state of building the app. We're actively working to make this process much more streamlined!

_You'll need Docker installed to run the app locally._
[Docker Desktop](https://www.docker.com/products/docker-desktop/) is an easy way to get started.

First, copy the `.env.example` file to `.env`:

```
cp .env.example .env
```

Then, create a new secret using `openssl rand -base64 32` and populate `NEXTAUTH_SECRET` in your `.env` file with it.

To enable transactional emails, you'll need to create a [Postmark](https://postmarkapp.com/) account and add your API key to your `.env` file (`NX_EMAIL_PROVIDER_API_TOKEN`) and set `NX_EMAIL_PROVIDER` to `postmark`. You can also set the from and reply-to email addresses (`NX_EMAIL_FROM_ADDRESS` and `NX_EMAIL_REPLY_TO_ADDRESS`). If you want to run the app without email, you can set `NX_EMAIL_PROVIDER_API_TOKEN` to a dummy value or leave `NX_EMAIL_PROVIDER` blank.

Maybe uses [Teller](https://teller.io/) for connecting financial accounts. To get started with Teller, you'll need to create an account. Once you've created an account:

-   Add your Teller application id to your `.env` file (`NEXT_PUBLIC_TELLER_APP_ID`).
-   Download your authentication certificates from Teller, create a `certs` folder in the root of the project, and place your certs in that directory. You should have both a `certificate.pem` and `private_key.pem`. **NEVER** check these files into source control, the `.gitignore` file will prevent the `certs/` directory from being added, but please double-check.
-   Set your `NEXT_PUBLIC_TELLER_ENV` and `NX_TELLER_ENV` to your desired environment. The default is `sandbox` which allows for testing with mock data. The login credentials for the sandbox environment are `username` and `password`. To connect to real financial accounts, you'll need to use the `development` environment.
-   Webhooks are not implemented yet, but you can populate the `NX_TELLER_SIGNING_SECRET` with the value from your Teller account.
-   We highly recommend checking out the [Teller docs](https://teller.io/docs) for more info.

Then run the following yarn commands:

```shell
yarn install
yarn run dev:services:all
yarn prisma:migrate:dev
yarn prisma:seed
yarn dev
```

## Set Up Ngrok

External data providers require HTTPS/SSL webhook URLs for sending data.

To test this locally/during development, you will need to setup `ngrok`.

1. Visit [ngrok.com](https://ngrok.com/)
2. Create a free account
3. Visit [this page](https://dashboard.ngrok.com/get-started/your-authtoken) to access your auth token
4. Paste it into your `.env` file: `NGROK_AUTH_TOKEN=your_auth_token`

You should claim your free static domain to avoid needing to change the URL each time you start/stop the server.

To do so:

1. Visit the [domains](https://dashboard.ngrok.com/cloud-edge/domains) page
2. Click on Create Domain
3. Copy the domain and paste it into your `.env` file: `NGROK_DOMAIN=your_domain`

That's it! As long as you run the project locally using `docker` with `yarn dev:services:all` you'll be good to go.

## Contributing

To contribute, please see our [contribution guide](https://github.com/maybe-finance/maybe/blob/main/CONTRIBUTING.md).

## High-priority issues

The biggest focus at the moment is on getting the app functional without some previously key external services (namely Plaid).

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
-   [Data model assumptions and calculations](https://github.com/maybe-finance/maybe/wiki/Data-model-assumptions-and-calculations)
-   [Handling money](https://github.com/maybe-finance/maybe/wiki/Handling-Money)
-   [REST API](https://github.com/maybe-finance/maybe/wiki/REST-API)

## Repo Activity

![Repo Activity](https://repobeats.axiom.co/api/embed/7866c9790deba0baf63ca1688b209130b306ea4e.svg 'Repobeats analytics image')

## Credits

The original app was built by [Zach Gollwitzer](https://twitter.com/zg_dev), [Nick Arciero](https://www.narciero.com/) and [Tim Wilson](https://twitter.com/actualTimWilson), with design work by [Justin Farrugia](https://twitter.com/justinmfarrugia). The app is currently maintained by [Josh Pigford](https://twitter.com/Shpigford).

## Copyright & license

Maybe is distributed under an [AGPLv3 license](https://github.com/maybe-finance/maybe/blob/main/LICENSE). "Maybe" is a trademark of Maybe Finance, Inc.

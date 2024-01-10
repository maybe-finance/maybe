![](https://github.com/maybe-finance/maybe/assets/35243/79d97b31-7fad-4031-9e83-5005bc1d7fd0)

# Maybe: Open-source personal finance app

<b>Get involved: [Discord](https://discord.gg/xfysSaSsfN) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

🚨 NOTE: This is the original React/Next.js app of the now-defunct personal finance app, Maybe. This original version used many external services (Plaid, Finicity, Auth0, etc) and getting it to fully function will be a decent amount of work.

The README below was what we used internally, so many of the links won't work and the instructions won't necessarily be applicable.

There's a LOT of work to do to get this functioning, but it should be feasible.

## Relevant reading...

* [Learn about how the app is organized as a monorepo](https://github.com/maybe-finance/maybe/wiki/Monorepo-File-Structure-Overview)

----

## ⚠️ Everything below is archived from the original repo and we're slowly working to replace/update it. 

# Quick Start

## System Prerequisites

-   Docker (if not using Docker, you will need Node LTS 14.7.x and Postgres 13.x)
-   (Optional, highly recommended) - Install the [NX Console](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console) for [using the nx client](#nrwl-nx-overview)

## Run the app locally

### Setup ENV

```
cp .env.example .env
```

A working local development `.env` file can be found in 1Password under the "Engineering" folder.

### With Docker (preferred)

#### Start server and client apps

```
yarn install
yarn dev
```

#### Migrate DB

In a separate terminal, run the following command. This will connect to the Postgres DB running inside Docker and run all the migrations in `/prisma/migrations`.

```
yarn prisma:migrate
```

You will also want to seed the database (includes account types and subtypes for categorization).

```
yarn prisma:seed
```

### Manually

_NOTE: Make sure Postgres 13.x is running on your machine_

```
yarn install
nx serve client # Terminal 1
nx serve server # Terminal 2
yarn prisma:migrate && yarn prisma:seed # Terminal 3 - after apps are running
```

# Reference

## Authentication

[See this wiki page](https://github.com/maybe-finance/maybe/wiki/Auth0) for an explanation of how authentication/authorization works in this codebase.

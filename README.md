<img width="1440" alt="dashboard" src="https://github.com/maybe-finance/maybe/assets/35243/4910781f-4bea-4a3b-8fb6-21f314548c9d">

# Maybe: The OS for your personal finances

<b>Get involved: [Discord](https://link.maybe.co/discord) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

_If you're looking for the previous React codebase, you can find it at [maybe-finance/maybe-archive](https://github.com/maybe-finance/maybe-archive)._

## Backstory

We spent the better part of 2021/2022 building a personal finance + wealth management app called, Maybe. Very full-featured, including an "Ask an Advisor" feature which connected users with an actual CFP/CFA to help them with their finances (all included in your subscription).

The business end of things didn't work out, and so we shut things down in mid-2023.

We spent the better part of $1,000,000 building the app (employees + contractors, data providers/services, infrastructure, etc.).

We're now reviving the product as a fully open-source project. The goal is to let you run the app yourself, for free, and use it to manage your own finances and eventually offer a hosted version of the app for a small monthly fee.

## Moving from React/Next.js to Ruby on Rails

The original codebase we open-sourced in January 2024 was a React/Next.js/Express app. There were a substantial number of issues with that codebase, rooted in large part to the requirements for SOC2 and SEC compliance and our dependency on a number of third-party data providers. Not to mention that a lot of the tech has changed in the React world since 2021.

As we started digging into the changes that would be required to get the app fully up and running again, we realized we'd actually end up rewriting the vast majority of the app. So instead of doing that in an incredibly slow and painful way, we decided to start from scratch with a new codebase. Yes, that's risky. But so is trying to rebuild a complex app on a codebase that's 3 years old and wasn't originally built for the requirements we now have.

We're now building the app in Ruby on Rails. We realize that's a controversial choice, but we believe it's the right one for the project. Rails is a mature, stable, and well-documented framework that's been around for over 20 years built on a language that's been around for over 30 years.

From the start, our focus with this is to make it as easy as possible for you to both contribute to and deploy the app, and this move to Rails is a big part of that.

## Codebase

The codebase is vanilla [Rails](https://rubyonrails.org/) and [Postgres](https://www.postgresql.org/). Quite a simple setup.

# Getting Started
## Requirements
## Devcontainer
This project supports devcontainer, so the only requirement is [Docker](https://www.docker.com) and [VSCode](https://code.visualstudio.com/) or any other editor that supports devcontainer and Ruby.
> **Note:** If you're using VSCode, you need to install the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

> **Note:** If you're using Windows, you need to have **[WSL2](https://learn.microsoft.com/en-us/windows/wsl/)** installed and running on your machine to use Docker (since devcontainer uses Docker to run the app). **[Here](https://docs.microsoft.com/en-us/windows/wsl/install)** is the official documentation to install **[WSL2](https://learn.microsoft.com/en-us/windows/wsl/)**.

### Linux
 -  Ruby `>3` (a specific version is in `Gemfile`)
 -  Postgresql `>9.3` (if using stock `config/database.yml`)
 -  Docker *(optional)*

### Windows
 -  Ruby+Devkit `>3` (a specific version is in `Gemfile`) (You can use **[RubyInstaller](https://rubyinstaller.org/downloads/)** or **[Chocolatey](https://chocolatey.org/packages/ruby)** (*devkit is not included in the Choco installer*) )
 -  Postgresql `>9.3` (if using stock `config/database.yml`) (You can use **[Postgresql Official Download page](https://www.postgresql.org/download/windows/)** or **[Chocolatey](https://chocolatey.org/packages/postgresql)**)
 -  Docker *(optional)* (You can use **[Docker Desktop](https://www.docker.com/products/docker-desktop)**)

> **Note:** If you want to skip the installation of Postgresql, you can use [docker-compose.yaml](docker-compose.yaml) to run a Postgresql container.


## Setup
Run the following commands after cloning the repo:
### Dependencies setup
```shell
bundle install
```

### Database setup
> **Note:** It will create the database, run the migrations, and seed the database. Please make sure you have Postgresql installed and running.
> 
> If you want to use the docker-compose file, you can run `docker compose up -d` to start the Postgresql container.
```shell
rails db:setup
```

### Env setup
```shell
cp .env.example .env
```

### Email Setup (Optional)
In development, we use `letter_opener` to automatically open emails in your browser. However, if you self-host, you'll likely want some basic email sending abilities.

You can use any SMTP-based mail service and then drop in your SMTP credentials in the `.env` file.

[Resend](https://resend.com) or [Brevo (formerly SendInBlue)](https://www.brevo.com/) is a great option for personal use as they have a very generous free plan.

# Running the app
## Quickly start the app with:
```shell
bin/dev
```
And visit [http://localhost:3000](http://localhost:3000)

## Project commands
### Server
```shell
rails s
```
### TailwindCSS watcher
```shell
rails tailwindcss:watch
```

### Database setup
```shell
rails db:setup
```

### Run tests
```shell
rails test
```
or 
```shell
rake test
```

# Contributing

Before contributing, you'll likely find it helpful to [understand context and general vision/direction](https://github.com/maybe-finance/maybe/wiki).

It is still very early days for this, so your mileage will vary here and lots of things will break.

But almost any contribution will be beneficial at this point. Check the [current Issues](https://github.com/maybe-finance/maybe/issues) to see where you can jump in!

If you've got an improvement, just send in a pull request!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

If you've got feature ideas, simply [open a new issue](https://github.com/maybe-finance/maybe/issues/new)!

## Repo Activity

![Repo Activity](https://repobeats.axiom.co/api/embed/7866c9790deba0baf63ca1688b209130b306ea4e.svg "Repobeats analytics image")

# Copyright & license

Maybe is distributed under an [AGPLv3 license](https://github.com/maybe-finance/maybe/blob/main/LICENSE). "Maybe" is a trademark of Maybe Finance, Inc.

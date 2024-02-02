<img width="1440" alt="dashboard" src="https://github.com/maybe-finance/maybe/assets/35243/4910781f-4bea-4a3b-8fb6-21f314548c9d">

# Maybe: The OS for your personal finances

<b>Get involved: [Discord](https://link.maybe.co/discord) • [Website](https://maybe.co) • [Issues](https://github.com/maybe-finance/maybe/issues)</b>

_If you're looking for the previous React codebase, you can find it at [maybe-finance/maybe-archive](https://github.com/maybe-finance/maybe-archive)._

## Backstory

We spent the better part of 2021/2022 building a personal finance + wealth management app called, Maybe. Very full-featured, including an "Ask an Advisor" feature which connected users with an actual CFP/CFA to help them with their finances (all included in your subscription).

The business end of things didn't work out, and so we shut things down mid-2023.

We spent the better part of $1,000,000 building the app (employees + contractors, data providers/services, infrastructure, etc.).

We're now reviving the product as a fully open-source project. The goal is to let you run the app yourself, for free, and use it to manage your own finances and eventually offer a hosted version of the app for a small monthly fee.

## Moving from React/Next.js to Ruby on Rails

The original codebase we open-sourced in January 2024 was a React/Next.js/Express app. There were a substantial number of issues with that codebase, rooted in large part to the requirements for SOC2 and SEC compliance and our dependency on a number of third-party data providers. Not to mention that a lot of the tech has changed in the React world since 2021.

As we started digging into the changes that would be required to get the app fully up and running again, we realized we'd actually end up rewriting the vast majority of the app. So instead of doing that in an incredibly slow and painful way, we decided to start from scratch with a new codebase. Yes, that's risky. But so is trying to rebuild a complex app on a codebase that's 3 years old and wasn't originally built for the requirements we now have.

We're now building the app in Ruby on Rails. We realize that's a controversial choice, but we believe it's the right one for the project. Rails is a mature, stable, and well-documented framework that's been around for over 20 years built on a language that's been around for over 30 years.

From the start our focus with this is to make it as easy as possible for you to both contribute to and deploy the app, and this move to Rails is a big part of that.

## Codebase

The codebase is vanilla [Rails](https://rubyonrails.org/) and [Postgres](https://www.postgresql.org/). Quite a simple setup.

## Setup

You'll need:

- ruby >3 (specific version is in `Gemfile`)
- postgresql (if using stock `config/database.yml`)

For convenience, the project contains configuration for a devcontainer. Open up the project in your editor that supports devcontainers and run the commands mentioned below.

```shell
cd maybe
bundle install
rails db:setup
```

You can then run the rails web server:

```shell
bin/dev
```

And visit [http://localhost:3000](http://localhost:3000)

## Contributing

Before contributing, you'll likely find it helpful to [understand context and general vision/direction](https://github.com/maybe-finance/maybe/wiki).

It's still very early days for this so your mileage will vary here and lots of things will break.

But almost any contribution will be beneficial at this point. Check the [current Issues](https://github.com/maybe-finance/maybe/issues) to see where you can jump in!

If you've got an improvement, just send in a pull request!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

If you've got feature ideas, simply [open a new issues](https://github.com/maybe-finance/maybe/issues/new)!

## Repo Activity

![Repo Activity](https://repobeats.axiom.co/api/embed/7866c9790deba0baf63ca1688b209130b306ea4e.svg "Repobeats analytics image")

## Copyright & license

Maybe is distributed under an [AGPLv3 license](https://github.com/maybe-finance/maybe/blob/main/LICENSE). "Maybe" is a trademark of Maybe Finance, Inc.

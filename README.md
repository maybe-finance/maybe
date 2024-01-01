# Maybe

We're in the earliest stages (exploratory, really) of building an open source investment tracking + optimization platform.

In its previous life, Maybe was a personal finance and wealth management platform that unfortunately wasn't economically viable. We're now taking another pass in the finance space to see how we can help people grow their wealth in meaningful ways.

If you're interested in being involved, head over to Discord: https://discord.gg/jhQFEMwrxD

You can also reach out to [@Shpigford](https://twitter.com/Shpigford) on Twitter.

![CleanShot 2024-01-01 at 16 10 05@2x](https://github.com/maybe-finance/maybe/assets/35243/056309d5-1890-4865-9936-481908dd7d5b)

## Code

The codebase is vanilla [Rails](https://rubyonrails.org/) w/ [Redis](https://redis.io/), [Puma](http://puma.io/), and [Postgres](https://www.postgresql.org/). Quite a simple setup.

### Setup

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

And visit [http://localhost:3000](http://localhost:3000)

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

# Resque::CloudWatch::Metrics

Send Resque.info to CloudWatch Metrics

[![Gem Version](https://badge.fury.io/rb/resque-cloudwatch-metrics.svg)](https://badge.fury.io/rb/resque-cloudwatch-metrics)
[![Code Climate](https://codeclimate.com/github/m4i/resque-cloudwatch-metrics/badges/gpa.svg)](https://codeclimate.com/github/m4i/resque-cloudwatch-metrics)
[![Dependency Status](https://gemnasium.com/badges/github.com/m4i/resque-cloudwatch-metrics.svg)](https://gemnasium.com/github.com/m4i/resque-cloudwatch-metrics)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resque-cloudwatch-metrics'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-cloudwatch-metrics

Or use Docker:

    $ docker run --rm m4i0/resque-cloudwatch-metrics --help

## Usage

```
Usage: resque-cloudwatch-metrics [options]
        --namespace <namespace>
        --interval <seconds>
        --dryrun
    -h, --host <host>
    -p, --port <port>
    -s, --socket <socket>
    -a, --password <password>
    -n, --db <db>
        --url <url>
        --redis-namespace <namespace>
        --[no-]pending
        --[no-]processed
        --[no-]failed
        --[no-]queues
        --[no-]workers
        --[no-]working
        --[no-]pending-per-queue
        --[no-]not-working
        --[no-]processing
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/m4i/resque-cloudwatch-metrics. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

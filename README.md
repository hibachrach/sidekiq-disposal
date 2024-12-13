# Sidekiq::Disposal

A mechanism to mark Sidekiq Jobs to be disposed of by Job ID, Batch ID, or Job Class.
Disposal here means to either `:kill` the Job (send to the Dead queue) or `:discard` it (throw it away), at the time the job is picked up and processed by Sidekiq.

## Installation

Install the gem and add to the application's Gemfile by executing:

```console
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```console
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/rspec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`.
To release a new version, update the version number in `version.rb`, and then run `bin/rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hibachrach/sidekiq-disposal.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

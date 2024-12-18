# Sidekiq::Disposal

[![Gem Version](https://badge.fury.io/rb/sidekiq-disposal.svg?icon=si%3Arubygems&icon_color=%23ff2600)](https://badge.fury.io/rb/sidekiq-disposal)

A [Sidekiq][sidekiq] extension to mark Sidekiq Jobs to be disposed of based on the Job ID, Batch ID, or Job Class.
Disposal here means to either `:kill` the Job (send to the Dead queue) or `:drop` it (throw it away), at the time the job is picked up and processed by Sidekiq.
A disposed Job's `#perform` method will _not_ be called.

Disposing of queued Jobs is particularly useful as a mitigation technique during an incident.
For example, an issue with a 3rd party API that causes Jobs of a certain Class to take longer than expected/normal to run.
Or a code change/edge case that unexpectedly fans out more than expected, enqueuing a large volume of Jobs which then drown out other Jobs.
Or… any number of other ways that some Job, Batch, or Job Class has been enqueued, but you [don't want it to actually run][cancel-jobs].

`sidekiq-disposal` has your back!

## Installation

Install the gem and add to the application's Gemfile by executing:

```console
bundle add sidekiq-disposal
```

If bundler is not being used to manage dependencies, install the gem by executing:

```console
gem install sidekiq-disposal
```

## Usage

From a console (Rails console, or the like) you need a `Sidekiq::Disposal::Client` instance, which is used to `#mark` a Job, Batch, or Job Class to be disposed.

```ruby
client = Sidekiq::Disposal::Client.new
```

### Marking to Kill

A Job marked to be killed means it will be moved to the Dead queue.

```ruby
# Mark a specific Job to be killed by specifying its Job ID
client.mark(:kill, :jid, some_job_id)

# Mark a Batch of Jobs to be killed, by Batch ID
client.mark(:kill, :bid, some_batch_id)

# Mark an entire Job Class to be killed
client.mark(:kill, :bid, "SomeJobClass")
```

A Job, Batch, or Job Class can also be `#unmarked` for disposal via a corresponding API.

```ruby
# Un-mark a specific Job from being killed, by Job ID
client.unmark(:kill, :jid, some_job_id)

# Un-mark a Batch of Jobs from being killed, by Batch ID
client.unmark(:kill, :bid, some_batch_id)

# Un-mark an entire Job Class from being killed
client.unmark(:kill, :bid, "SomeJobClass")
```

### Marking to Drop

Similarly, a Job, Batch, or Job Class can be marked to be dropped.
Dropped jobs are discarded by Sidekiq - think of them as simply being deleted from the queue, without ever being run.

```ruby
# Mark a specific Job to be dropped by specifying its Job ID 
client.mark(:drop, :jid, some_job_id)

# Mark a Batch of Jobs to be dropped, by Batch ID
client.mark(:drop, :bid, some_batch_id)

# Mark an entire Job Class to be dropped
client.mark(:drop, :bid, "SomeJobClass")
```

And again, there is a corresponding API for un-marking a Job, Batch, or Job Class from being dropped.

```ruby
# Un-mark a specific Job from being dropped, by Job ID
client.unmark(:drop, :jid, some_job_id)

# Un-mark a Batch of Jobs from being dropped, by Batch ID
client.unmark(:drop, :bid, some_batch_id)

# Un-mark an entire Job Class from being dropped
client.unmark(:drop, :bid, "SomeJobClass")
```

### Un-marking All

Clearing all `:kill` or `:drop` marks can be done in one fell swoop as well.

```ruby
client.unmark_all(:kill)

# or …

client.unmark_all(:drop)
```

## Configuration

With `sidekiq-disposal` installed, [register its Sidekiq server middleware][sidekiq-register-middleware].
Typically this is done via `config/initializers/sidekiq.rb` in a Rails app.

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Disposal::ServerMiddleware
  end
end
```

This piece of middleware checks each job, after it's been dequeued, but before its `#perform` has been called, to see if it should be disposed of.
If the job is marked for disposal (by Job ID, Batch ID, or Job Class), a corresponding error is raised by the middleware.

A Job marked `:kill` will raise a `Sidekiq::Disposal::JobKilled` error, while one marked `:drop` will raise `Sidekiq::Disposal::JobDropped`.
Out of the box, these errors will cause [Sidekiq's error handling and retry mechanism][sidekiq-retries] to kick in, re-enqueueing the Job.
And round-and-round it will go until the default error/death handling kicks in.

To avoid this, you need to handle those specific `Sidekiq::Disposal` errors accordingly.

Adjust the base Sidekiq Job class, often called `ApplicationJob` or similar, so the `sidekiq_retry_in` uses a block similar to this:

```ruby
sidekiq_retry_in do |_count, exception, jobhash|
  case exception
  when Sidekiq::Disposal::JobKilled
    # Optionally log/collect telemetry here too…
    :kill
  when Sidekiq::Disposal::JobDropped
    # Optionally log/collect telemetry here too…
    :discard
  end
end
```

_NOTE_: If is not a base job, consider adding one, or you'll need to add this to every job you want to be disposable.

Returning `:kill` from this method will cause Sidekiq to immediately move the Job to the Dead Queue.
Similarly, returning `:discard` will cause Sidekiq to drop the job on the floor.
Either way, the Job's `#perform` is never called.

### Non-Disposable Jobs

By default all Jobs are disposable, meaning they _can_ be marked to be `:kill`-ed or `:drop`-ed.
However, checking if a specific Job should be disposed of is not free; it requires round trip(s) to Redis.
Therefore, you might want to make some Jobs non-disposable to avoid these extra round trips.
Or because there are some Jobs that simply should never be disposed of for… _reasons_.

This is done via a Job's `sidekiq_options`.

```ruby
sidekiq_options disposable: false
```

With that in place, the server middleware will ignore the Job, and pass it down the middleware Chain.
No extra Redis calls, no funny business.

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

[sidekiq]: https://sidekiq.org "Simple, efficient background jobs for Ruby."
[sidekiq-register-middleware]: https://github.com/sidekiq/sidekiq/wiki/Middleware#registering-middleware "Registering Sidekiq Middleware"
[sidekiq-retries]: https://github.com/sidekiq/sidekiq/wiki/Error-Handling "Sidekiq Error Handling and Retries"
[cancel-jobs]: https://github.com/sidekiq/sidekiq/wiki/FAQ#how-do-i-cancel-a-sidekiq-job "How do I cancel a Sidekiq Job?"

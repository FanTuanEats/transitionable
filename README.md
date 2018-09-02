# Transitionable

A convention-based state machine that complements your models without stealing the show.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transitionable'
```

And then execute:

    $ bundle

## Usage

```ruby
class Event

  # Requires including class to define the following constants BEFORE including this module:
  #
  #  * STATES
  #  * TRANSITIONS

  STATES = {
    STAGED:    'staged',
    STARTED:   'started',
    COMPLETED: 'completed'
  }.freeze

  TRANSITIONS = [
    { from: STATES[:STAGED], to: STATES[:STARTED] },
    { from: STATES[:STARTED], to: STATES[:COMPLETED] }
  ].freeze

  include Transitionable

  # specifies the column that needs to be transitioned
  transition :some_state

end
```

Provides the following helpers

```ruby
event.staged?
event.started?
event.completed?
```

Provides 2 validation methods

```ruby
event.validate_transition(target_state: 'new_state')
# => returns true or false

event.validate_transition!(target_state: 'new_state')
# => returns true or raises Transitionable::InvalidStateTransition exception
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/transitionable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

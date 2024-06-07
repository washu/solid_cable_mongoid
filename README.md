# SolidCableMongoid

Solid Cable Mongoid is a DB-based backend for Action Cable, using Mongoid and MongoDB


## Installation
Add this line to your application's Gemfile:

```ruby
gem "solid_cable_mongoid"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install solid_cable_mongoid
```

Update `config/cable.yml` to use the new adapter. collection_prefix is optional and defaults to "solid_cable_"
The collections we also assume the default client connection, to override and use an alternate client connection, set the `client` key in the configuration to the name of the client connection you want to use.
The expiration time for the message is set to 1 minute by default, to override this set the `expiration` key in the configuration to the desired expiration time in seconds.
```yaml
development:
  adapter: solid_cable_mongoid
  collection_prefix: "dev_cable_"
  expiration: 60

test:
  adapter: test

production:
  adapter: solid_cable_mongoid
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

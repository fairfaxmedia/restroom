# Restroom

Restroom provides a DSL to quickly and easily describe a RESTful and build a gem around it. It was extracted during the development of a Bitbucket API gem, thus the examples below.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'restroom'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install restroom

## Usage

Here's the client code from the [Bitbucket2](http://github.com/fairfaxmedia/bitbucket2) gem:

```ruby
module Bitbucket2
  class Client
    include Restroom

    restroom 'https://api.bitbucket.org', base_path: '2.0' do
      exposes :repositories, model: Repository, id: :full_name do
        exposes :commits, model: Commit, id: :hash
        exposes :pull_requests, resource: 'pullrequests', model: PullRequest do
          exposes :commits, model: Commit, id: :hash
        end
      end
    end
  end
end
```

...and that's it - apart from some simple model files (for which I like to use Virtus):

```ruby
module Bitbucket2
  class Commit
    include Virtus.model

    attribute :hash, String
  end
end
```

...which are instantiated with a hash of attributes extracted from the API's returned JSON.

The `exposes` invocation takes several options:

 - a key which is used to build the relation methods (so we can call Bitbucket2::Client.new.repositories, in this case),
 - a class (model) to instantiate,
 - a id for building nested paths (so in the case of repositories we use the `full_name` attribute).

### Authentication

A Faraday::Connection object is passed into the `stack` method. This provides
opportunity to configure options such as an authentication method:

```ruby
module ModuleName
  class Client
    include Restroom

    AUTH_TOKEN = 'very_secure_token'

    restroom 'https://my-domain.com' do
      exposes :some_endpoint, model: ModelName
    end

    def self.stack(config)
      config.token_auth(AUTH_TOKEN)
    end
  end
end
```

See the [Faraday documentation](https://github.com/lostisland/faraday#authentication)
for more examples.

### Preparing responses

Often times, the response from an API does not directly match the layout of your
model (for example, the object/s could be wrapped in a `data` key). In these
situations, you can supply a `response_filter` either as a class method for all
endpoints or in the `expose` invocation:

```ruby
module ModuleName
  class Client
    include Restroom

    restroom 'https://my-domain.com' do
      exposes :some_endpoint, model: ModelName, response_filter: proc { |_, data| data['some_key'] }
    end

    # Response like: { data: [{key: value}, {key: value}]}
    def self.response_filter
      proc { |_, data| data['data'] }
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at http://github.com/fairfaxmedia/restroom.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

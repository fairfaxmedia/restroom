# Restroom

Restroom provides a DSL to quickly and easily describe a RESTful and build a gem around it. I was extracted during the development of a Bitbucket API gem, thus the examples below.

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

Here's the client code from the [Bitbucket2](http://github.com/fairfax/bitbucket2) gem:

```
module Bitbucket2
  class Client
    include Restroom

    def token_callable
      ... oath token code
    end

    restroom 'https://api.bitbucket.org', base_path: '2.0', oauth2_token_method: token_callable do |bitbucket|
      bitbucket.exposes :repositories, class: Repository, id: :full_name do |repository|
        repository.exposes :commits, class: Commit, id: :hash
        repository.exposes :pull_requests, resource: 'pullrequests', class: PullRequest do |pull_request|
          pull_request.exposes :commits, class: Commit, id: :hash
        end
      end
    end
  end
end
```

...and that's it - apart from some simple model files (for which I like to use Virtus):

```
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
 - a class to instantiate,
 - a id for building nested paths (so in the case of repositories we use the `full_name` attribute).


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[fairfax]/restroom.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

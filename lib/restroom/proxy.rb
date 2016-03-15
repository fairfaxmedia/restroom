require 'restroom/relation'

module Restroom
  class Proxy
    include Relation
    attr_reader :instance, :dsl

    def initialize(instance, dsl)
      @instance = instance
      @dsl = dsl
    end

    def response_filter
      dsl.response_filter
    end

    def resource
      dsl.resource
    end

    def model
      dsl.model
    end

    def id_method
      dsl.id
    end

    def parent
      instance.restroom_parent
    end

    def connection
      parent.connection
    end

    def build data={}
      model.new(data).tap do |obj|
        obj.restroom_parent = self
      end
    end

    def instance_id
      instance.send(dsl.parent.id)
    end

    def expand_path *path
      path.compact.join('/')
    end

    def resource_path
      expand_path(parent.resource_path, instance_id, resource)
    end

    def singular_path(key)
      expand_path(resource_path, key)
    end

    def plural_path
      resource_path
    end

    def parsed_response body
      JSON.parse body
    rescue JSON::ParseError
      raise ApiError, "couldn't parse response: #{body[0..20]}"
    end

    def filter_result(path, params={})
      response_filter.call parsed_response(request(:get, path, params))
    end

    def get key
      build filter_result(singular_path(key))
    end

    def filter filter, params={}
      filter_result(expand_path(resource_path, filter), params).map { |data| build data }
    end

    def all params={}
      filter_result(plural_path, params).map { |data| build data }
    end

    def request method, path, args={}
      response = connection.send(method, path, args)
      if (200...300).include? response.status
        return response.body
      else
        raise AuthenticationError, 'unauthorised' if response.status == 401
        raise AuthenticationError, 'forbidden' if response.status == 403
        raise ApiError
      end
    rescue Faraday::ClientError => e
      raise NetworkError, e.message
    end
  end
end

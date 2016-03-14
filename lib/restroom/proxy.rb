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
      dsl.children[key].response_filter
    end

    def key
      dsl.key
    end

    def resource
      dsl.resource
    end

    def klass
      dsl.klass || resource.to_s.classify.constantize
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
      klass.new(data).tap do |obj|
        obj.restroom_parent = self
      end
    end

    def instance_id
      instance.send(parent.id_method) if parent.respond_to? :id_method
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

    def plural_response(params)
      connection.get(plural_path).body
    end

    def extract_plural_results params
      response_filter.call JSON.parse(plural_response(params))
    end

    def singular_response(key)
      connection.get(singular_path(key))
    end

    def extract_singular_result(key)
      response_filter.call JSON.parse(singular_response(key).body)
    end

    def get key
      build extract_singular_result(key)
    end

    def all params={}
      extract_plural_results(params).map {|data| build data }
    end
  end
end

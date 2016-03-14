require "restroom/version"
require 'restroom/proxy'
require 'restroom/relation'
require 'restroom/dsl'

require 'active_support/inflector'
require 'faraday'
require 'faraday_middleware'
require 'json'


module Restroom
  def self.included(base)
    base.extend(ClassMethods)
  end

  def restroom_parent
    self.class
  end

  module ClassMethods
    attr_reader :endpoint, :base_path

    def restroom(endpoint, base_path: nil, &block)
      @endpoint = endpoint
      @base_path = base_path
      DSL.new(host: self, parent: self).tap do |dsl|
        dsl.wrapper(&block)
      end
    end

    def resource_path
      base_path
    end

    def klass
      self
    end

    def response_filter
      default_response_filter
    end

    def default_response_filter
      Proc.new { |x| x }
    end

    def connection
      @connection ||= Faraday.new endpoint do |config|
        config.adapter Faraday.default_adapter
        stack(config) if respond_to? :stack
      end
    end
  end
end

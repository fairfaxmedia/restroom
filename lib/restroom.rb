require "restroom/version"
require 'restroom/proxy'
require 'restroom/relation'
require 'restroom/context'

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

  def id
    nil
  end

  module ClassMethods
    attr_reader :endpoint, :base_path

    def restroom(endpoint, base_path: nil, &block)
      @endpoint = endpoint
      @base_path = base_path
      Context.build(host: self, parent: self, &block)
    end

    def resource_path
      base_path
    end

    def model
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
        stack(config) if respond_to? :stack
        config.adapter Faraday.default_adapter
      end
    end
  end

  class ApiError < StandardError; end
  class NetworkError < StandardError; end
  class AuthenticationError < StandardError; end
end

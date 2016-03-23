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
      Context.new(host: self, parent: self, &block)
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
      Proc.new { |mode, response| response }
    end

    def stack
    end

    def connection
      @connection ||= Faraday.new endpoint do |config|
        stack(config)
        config.adapter Faraday.default_adapter
      end
    end
  end

  class Error < StandardError; end
  class ApiError < Error; end
  class DataError < Error; end
  class NetworkError < Error; end
  class AuthenticationError < Error; end
end

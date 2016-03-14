require 'restroom/relation'

module Restroom
  class DSL
    attr_accessor :host, :parent, :resource, :klass, :id, :response_filter, :children, :key

    def initialize host: nil, parent: nil
      @host = host
      @parent = parent
      @children = {}
    end

    def set key, value
      send "#{key}=", value
    end

    def response_filter
      @response_filter || parent.response_filter
    end

    def wrapper parent: nil, &block
      self.instance_eval &block if block_given?

      @children.each do |key, dsl|
        dsl.host = @parent.klass if @parent
        dsl.host.include(Relation)
        dsl.host.add_relation(key, self)
      end
    end

    def exposes k=nil, **args, &block
      child = self.class.new(parent: self)

      @key      ||= k
      @resource ||= args[:resource] || key
      @klass    ||= args[:class]
      @id       ||= args[:id] || :id

      @children[key] = child

      child.wrapper(&block)

      # TODO change this to instance injection instead of a class attribute - eigenclass?
      @klass.send(:attr_accessor, :restroom_parent)
    end

    def dump
      draw_dump(self, 'base', 0)
    end

    def draw_dump(dsl, k, depth)
      puts "#{' ' * depth * 2}#{k}: #{dsl.host} #{dsl.parent} #{dsl.resource}, #{dsl.klass}, #{dsl.id}, #{dsl.response_filter}"
      dsl.children.each { |key, child| draw_dump(child, key, depth+1) }
    end
  end
end

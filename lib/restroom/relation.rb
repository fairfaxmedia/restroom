module Restroom
  module Relation
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def add_relation key, dsl
        # TODO Check for collision
        define_method key do
          Proxy.new self, dsl
        end
      end
    end
  end
end

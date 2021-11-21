require "flipper/expression"

module Flipper
  module Expressions
    class Value < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        args[0]
      end
    end
  end
end

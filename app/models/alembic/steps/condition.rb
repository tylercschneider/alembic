module Alembic
  module Steps
    class Condition
      include Flow::Step

      label "Condition"

      setting :answer, type: :text
      setting :equals, type: :text
      setting :in, type: :list

      outputs :yes, :no

      requires { |node| [ node.config["answer"] ].compact }

      def route(node, state)
        holds?(node.config, state) ? :yes : :no
      end

      private

      def holds?(config, state)
        tested = state[config["answer"]]
        return Array(config["in"]).include?(tested) if config["in"].present?

        tested == config["equals"]
      end
    end
  end
end

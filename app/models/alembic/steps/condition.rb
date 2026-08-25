module Alembic
  module Steps
    class Condition
      include Flow::Step

      label "Condition"

      field :answer, :string
      field :equals, :string
      field :in, :list

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

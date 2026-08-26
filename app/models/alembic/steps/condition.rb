module Alembic
  module Steps
    class Condition
      include Flow::Step

      step_name "Condition"

      setting :step, type: :string
      setting :answer, type: :string
      setting :equals, type: :string
      setting :in, type: :list do
        setting :value, type: :string
      end

      outputs :yes, :no

      requires { |node| [ node.config["answer"] ].compact }

      def route(node, state)
        holds?(node.config, state) ? :yes : :no
      end

      private

      def holds?(config, state)
        tested = state[config["answer"]]
        return chosen(config).include?(tested) if chosen(config).any?

        tested == config["equals"]
      end

      def chosen(config)
        Array(config["in"]).map { |entry| entry.is_a?(Hash) ? entry["value"] : entry }.compact
      end
    end
  end
end

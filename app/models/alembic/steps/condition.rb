module Alembic
  module Steps
    module Condition
      def self.step_type
        Flow::StepType.define(:condition) do
          label "Condition"
          field :answer, :string
          field :equals, :string
          field :in, :list
          outputs :yes, :no

          requires { |node| [ node.config["answer"] ].compact }
          route { |node, state| Condition.holds?(node.config, state) ? :yes : :no }
        end
      end

      def self.register(registry = Flow.registry)
        registry.register(step_type)
      end

      def self.holds?(config, state)
        tested = state[config["answer"]]
        return Array(config["in"]).include?(tested) if config.key?("in")

        tested == config["equals"]
      end
    end
  end
end

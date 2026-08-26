module Alembic
  module Steps
    class Condition
      include Flow::Step

      step_name "Condition"

      setting :step, type: :previous_step
      setting :answer, from: :step

      output :result, type: :boolean, values: [ true, false ]

      ports :yes, :no

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        state[node.config["step"]] == node.config["answer"]
      end
    end
  end
end

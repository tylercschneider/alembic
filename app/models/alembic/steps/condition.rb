module Alembic
  module Steps
    class Condition
      include Flow::Step

      step_name "Condition"

      setting :step, type: :previous_step
      setting :answer, from: :step

      ports :yes, :no

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        state[node.config["step"]] == node.config["answer"] ? :yes : :no
      end
    end
  end
end

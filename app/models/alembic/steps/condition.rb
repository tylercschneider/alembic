module Alembic
  module Steps
    class Condition
      include Flow::Step

      step_name "Condition"

      setting :step, type: :previous_step, required: true
      setting :answer, from: :step, required: true

      output :result, type: :boolean, values: [ true, false ]

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        state[node.config["step"]] == node.config["answer"]
      end
    end
  end
end

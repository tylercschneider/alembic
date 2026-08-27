module Alembic
  module Flow
    class Switch
      include Step

      step_name "Switch"

      setting :step, type: :previous_step, required: true

      output :choice, type: :string, label: "Choice", from: :step

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        state[node.config["step"]]
      end
    end
  end
end

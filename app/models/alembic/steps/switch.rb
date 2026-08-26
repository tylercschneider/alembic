module Alembic
  module Steps
    class Switch
      include Flow::Step

      step_name "Switch"

      setting :step, type: :previous_step

      output :choice, type: :string, label: "Choice", from: :step

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        state[node.config["step"]]
      end
    end
  end
end

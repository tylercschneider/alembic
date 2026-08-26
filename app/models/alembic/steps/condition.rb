module Alembic
  module Steps
    class Condition
      include Flow::Step

      step_name "Condition"

      setting :step, type: :previous_step, required: true
      setting :output, outputs_of: :step, required: true
      setting :comparison, type: :select, options: [ "is", "is not" ], required: true
      setting :answer, from: :output, required: true

      output :result, type: :boolean, values: [ true, false ]

      names_by { |node| node.config.values_at("step", "comparison", "answer").compact_blank.join(" ").presence }

      requires { |node| [ node.config["step"] ].compact }

      def route(node, state)
        matched = state[node.config["step"]] == node.config["answer"]

        node.config["comparison"] == "is not" ? !matched : matched
      end
    end
  end
end

module Alembic
  module Steps
    module Question
      def self.step_type
        Flow::StepType.define(:question) do
          label "Question"
          field :text, :text
          field :options, :list
          awaits_input
        end
      end

      def self.register(registry = Flow.registry)
        registry.register(step_type)
      end
    end
  end
end

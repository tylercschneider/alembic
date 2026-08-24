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
        end
      end
    end
  end
end

module Alembic
  module Flow
    module Step
      extend ActiveSupport::Concern

      class_methods do
        def step_type
          StepType.define(step_type_id) { }
        end

        def step_type_id
          name.demodulize.underscore.to_sym
        end
      end
    end
  end
end

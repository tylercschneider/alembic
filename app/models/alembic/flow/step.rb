module Alembic
  module Flow
    module Step
      extend ActiveSupport::Concern

      WORDS = (StepType::Declaration.public_instance_methods(false) - [ :to_step_type ]).freeze

      included do
        class_attribute :declarations, default: []
      end

      class_methods do
        WORDS.each do |word|
          define_method(word) do |*arguments, **options, &block|
            self.declarations += [ [ word, arguments, options, block ] ]
          end
        end

        def step_type
          spoken = declarations
          StepType.define(step_type_id) do
            spoken.each { |word, arguments, options, block| public_send(word, *arguments, **options, &block) }
          end
        end

        def step_type_id
          name.demodulize.underscore.to_sym
        end
      end
    end
  end
end

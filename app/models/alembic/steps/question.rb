module Alembic
  module Steps
    class Question
      include Flow::Step

      step_name "Question"

      setting :name, type: :string
      setting :question, type: :string
      setting :category, type: :string
      setting :answers, type: :list do
        setting :value, type: :string
        setting :label, type: :string
        setting :weight, type: :integer
      end

      names_by :name, :question
      awaits_input

      def self.asked(step)
        step.to_h["question"] || step.to_h["text"]
      end

      def self.answers_of(step)
        Array(step.to_h["answers"] || step.to_h["options"])
      end

      def self.category_of(step)
        step.to_h["category"] || step.to_h["tag"]
      end
    end
  end
end

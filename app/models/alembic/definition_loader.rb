module Alembic
  class DefinitionLoader
    def initialize(definition)
      @definition = definition
    end

    OPTIONAL_COPY_KEYS = %w[headline kicker blurb start_label].freeze

    def build
      Guide.new(slug: @definition["slug"], questions: questions, **optional_copy)
    end

    private

    def questions
      Array(@definition["questions"]).map do |question|
        Guide::Question.new(id: question["id"].to_sym, text: question["text"], options: options_for(question), condition: condition_for(question))
      end
    end

    def condition_for(question)
      condition = question["condition"]
      return nil unless condition

      answer_key = condition["answer"].to_sym
      ->(answers) { answers[answer_key] == condition["equals"] }
    end

    def options_for(question)
      Array(question["options"]).map do |option|
        Guide::Option.new(value: option["value"], label: option["label"], hint: option["hint"])
      end
    end

    def optional_copy
      @definition.slice(*OPTIONAL_COPY_KEYS).transform_keys(&:to_sym)
    end
  end
end

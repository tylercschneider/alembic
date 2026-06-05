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
        Guide::Question.new(id: question["id"].to_sym, text: question["text"])
      end
    end

    def optional_copy
      @definition.slice(*OPTIONAL_COPY_KEYS).transform_keys(&:to_sym)
    end
  end
end

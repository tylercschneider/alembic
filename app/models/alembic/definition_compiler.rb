module Alembic
  class DefinitionCompiler
    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def to_definition
      {
        "slug" => @diagnostic.slug,
        "kicker" => @diagnostic.kicker,
        "headline" => @diagnostic.headline,
        "blurb" => @diagnostic.blurb,
        "start_label" => @diagnostic.start_label,
        "placement" => { "resolver_key" => @diagnostic.resolver_key },
        "questions" => compile_questions
      }
    end

    private

    def compile_questions
      @diagnostic.questions.ordered.map do |question|
        base = { "id" => question.key, "text" => question.text, "options" => compile_options(question) }
        condition = compile_condition(question)
        condition ? base.merge("condition" => condition) : base
      end
    end

    def compile_condition(question)
      condition = question.conditions.first
      return nil unless condition

      { "answer" => condition.tested_question.key, "equals" => condition.options.ordered.first.value }
    end

    def compile_options(question)
      question.options.ordered.map do |option|
        { "value" => option.value, "label" => option.label, "hint" => option.hint }
      end
    end
  end
end

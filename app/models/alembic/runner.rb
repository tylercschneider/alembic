module Alembic
  class Runner
    def initialize(definition)
      @definition = definition.to_h
      @digest = Flow::Digest.new(Flow::Document.new(@definition))
    end

    def slug
      @definition["slug"]
    end

    def headline
      @definition["headline"]
    end

    def questions
      @digest.steps.map { |node| question_from(node) }
    end

    def next_question(answers)
      asked = @digest.next_step(named(answers))

      question_from(asked) if asked
    end

    def answers_on_path(answers)
      @digest.state_on_path(named(answers)).symbolize_keys
    end

    def applicable_questions(answers)
      answers_on_path(answers).keys.map { |id| question_from(@digest.step(id.to_s)) }
    end

    def question_text(id)
      Steps::Question.asked(@digest.step(id.to_s)&.config)
    end

    def choice_label(id, value)
      chosen = choices_in(@digest.step(id.to_s)).find { |choice| choice.value == value }

      chosen&.label.presence || value
    end

    private

    def question_from(node)
      Asked.new(id: node.id.to_sym, text: Steps::Question.asked(node.config), choices: choices_in(node))
    end

    def choices_in(node)
      Steps::Question.answers_of(node.config).map { |option| choice_from(option) }
    end

    def choice_from(option)
      return Choice.new(value: option) unless option.is_a?(Hash)

      Choice.new(value: option["value"], label: option["label"], hint: option["hint"])
    end

    def named(answers)
      answers.transform_keys(&:to_s)
    end
  end
end

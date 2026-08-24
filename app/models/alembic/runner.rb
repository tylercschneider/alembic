module Alembic
  class Runner
    def self.for(definition)
      return new(definition) if definition.to_h.key?("nodes")

      DefinitionLoader.new(definition).build
    end

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

    def applicable_questions(answers)
      answers_on_path(answers).keys.map { |id| question_from(@digest.step(id.to_s)) }
    end

    def question_text(id)
      @digest.step(id.to_s)&.config&.fetch("text", nil)
    end

    def choice_label(id, value)
      chosen = choices_in(@digest.step(id.to_s)).find { |choice| choice.value == value }

      chosen&.label.presence || value
    end

    def scored?
      false
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

    private

    def question_from(node)
      Guide::Question.new(id: node.id.to_sym, text: node.config["text"], options: choices_in(node))
    end

    def choices_in(node)
      Array(node.config["options"]).map { |option| choice_from(option) }
    end

    def choice_from(option)
      return Guide::Option.new(value: option, label: option, hint: nil) unless option.is_a?(Hash)

      Guide::Option.new(value: option["value"], label: option["label"].presence || option["value"],
                        hint: option["hint"], weight: option["weight"])
    end

    def named(answers)
      answers.transform_keys(&:to_s)
    end
  end
end

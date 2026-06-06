module Alembic
  class DefinitionDecompiler
    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def load(definition)
      @diagnostic.update!(
        kicker: definition["kicker"],
        headline: definition["headline"],
        blurb: definition["blurb"],
        start_label: definition["start_label"],
        resolver_key: definition.dig("placement", "resolver_key")
      )
      build_questions(definition["questions"])
      build_conditions(definition["questions"])
    end

    private

    def build_questions(questions)
      Array(questions).each_with_index do |question, index|
        record = @diagnostic.questions.create!(key: question["id"], text: question["text"], position: index + 1)
        build_options(record, question["options"])
      end
    end

    def build_options(question, options)
      Array(options).each_with_index do |option, index|
        question.options.create!(value: option["value"], label: option["label"], hint: option["hint"], position: index + 1)
      end
    end

    def build_conditions(questions)
      Array(questions).each do |question|
        condition = question["condition"]
        next unless condition

        gated = @diagnostic.questions.find_by(key: question["id"])
        tested = @diagnostic.questions.find_by(key: condition["answer"])
        values = condition["in"] || [ condition["equals"] ]
        gated.conditions.create!(tested_question: tested, options: tested.options.where(value: values))
      end
    end
  end
end

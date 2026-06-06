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
    end

    private

    def build_questions(questions)
      Array(questions).each_with_index do |question, index|
        @diagnostic.questions.create!(key: question["id"], text: question["text"], position: index + 1)
      end
    end
  end
end

module Alembic
  class Diagnostic < ApplicationRecord
    enum :status, { draft: "draft", published: "published" }
    enum :kind, { scored: "scored", guide: "guide" }

    validates :slug, presence: true

    has_many :questions, dependent: :destroy
    has_many :bands, dependent: :destroy
    has_many :results, dependent: :destroy
    has_many :rules, dependent: :destroy

    def self.upsert_definition(definition)
      create!(slug: definition["slug"], definition: definition)
    end

    def to_guide
      DefinitionLoader.new(definition).build
    end

    def score(answers)
      answers.sum do |question_key, option_value|
        question = questions.find { |candidate| candidate.key == question_key }
        option = question&.options&.find { |candidate| candidate.value == option_value }
        option&.weight || 0
      end
    end

    def result_for(answers)
      band_for(score(answers))
    end

    def next_question(answers)
      questions.ordered.find { |question| question.applies?(answers) && !answers.key?(question.key) }
    end

    def complete?(answers)
      next_question(answers).nil?
    end

    def place(answers)
      rules.ordered.select { |rule| rule.fires?(answers) }
        .each_with_object({}) do |rule, placement|
          rule.results.each { |result| placement[result.slot] = result }
        end
    end

    def band_for(score)
      bands.sort_by { |band| band.ceiling || Float::INFINITY }
        .find { |band| band.ceiling.nil? || score < band.ceiling }
    end
  end
end

module Alembic
  class Diagnostic < ApplicationRecord
    enum :status, { draft: "draft", published: "published" }
    enum :kind, { scored: "scored", guide: "guide" }

    validates :slug, presence: true

    has_many :questions, dependent: :destroy
    has_many :nodes, dependent: :destroy
    has_many :warnings, dependent: :destroy
    has_many :bands, dependent: :destroy
    has_many :domains, dependent: :destroy
    # Declared before :results so their rule_results clear first, otherwise
    # destroying a diagnostic trips the rule_results -> results FK.
    has_many :rules, dependent: :destroy
    has_many :results, dependent: :destroy

    def self.upsert_definition(definition)
      find_or_initialize_by(slug: definition["slug"]).tap do |diagnostic|
        diagnostic.update!(definition: definition)
      end
    end

    def to_guide
      DefinitionLoader.new(definition).build
    end

    def compile!
      update!(definition: DefinitionCompiler.new(self).to_definition)
    end

    def revert!
      DefinitionDecompiler.new(self).load(definition)
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

    def overall_percentage(answers)
      percentage_of(questions, answers)
    end

    def domain_percentages(answers)
      domains.index_with { |domain| percentage_of(domain.questions, answers) }
    end

    def band_for(score)
      bands.sort_by { |band| band.ceiling || Float::INFINITY }
        .find { |band| band.ceiling.nil? || score < band.ceiling }
    end

    private

    def percentage_of(questions, answers)
      (captured_weight(questions, answers).to_f / weight_on_offer(questions) * 100).round
    end

    def captured_weight(questions, answers)
      questions.sum { |question| weight_of(question, answers[question.key]) }
    end

    def weight_on_offer(questions)
      questions.sum { |question| question.options.maximum(:weight) || 0 }
    end

    def weight_of(question, value)
      question.options.find { |option| option.value == value }&.weight || 0
    end
  end
end

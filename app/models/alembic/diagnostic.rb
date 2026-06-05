module Alembic
  class Diagnostic < ApplicationRecord
    enum :status, { draft: "draft", published: "published" }
    enum :kind, { scored: "scored", guide: "guide" }

    validates :slug, presence: true

    has_many :questions, dependent: :destroy
    has_many :bands, dependent: :destroy
    has_many :results, dependent: :destroy
    has_many :rules, dependent: :destroy

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

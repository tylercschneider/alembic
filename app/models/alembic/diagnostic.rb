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
    # Declared before :definition_versions so responses clear first, otherwise
    # destroying a diagnostic trips the responses -> definition_versions FK.
    has_many :responses, dependent: :destroy
    has_many :definition_versions, dependent: :destroy
    # Declared before :results so their rule_results clear first, otherwise
    # destroying a diagnostic trips the rule_results -> results FK.
    has_many :rules, dependent: :destroy
    has_many :results, dependent: :destroy

    def self.upsert_definition(definition)
      find_or_initialize_by(slug: definition["slug"]).tap do |diagnostic|
        diagnostic.save!
        diagnostic.record_definition(definition) unless diagnostic.definition == definition
      end
    end

    def definition
      current_definition_version&.definition
    end

    def current_definition_version
      definition_versions.order(:number).last
    end

    def record_definition(payload)
      definition_versions.create!(number: next_definition_number, definition: payload)
    end

    def to_guide
      DefinitionLoader.new(definition).build
    end

    def compile!
      record_definition(DefinitionCompiler.new(self).to_definition)
    end

    def revert!
      DefinitionDecompiler.new(self).load(definition)
    end

    def place(answers)
      rules.ordered.select { |rule| rule.fires?(answers) }
        .each_with_object({}) do |rule, placement|
          rule.results.each { |result| placement[result.slot] = result }
        end
    end

    private

    def next_definition_number
      (definition_versions.maximum(:number) || 0) + 1
    end
  end
end

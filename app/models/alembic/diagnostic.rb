module Alembic
  class Diagnostic < ApplicationRecord
    enum :status, { draft: "draft", published: "published" }
    enum :kind, { scored: "scored", guide: "guide" }

    validates :slug, presence: true

    # Declared before :definition_versions so responses clear first, otherwise
    # destroying a diagnostic trips the responses -> definition_versions FK.
    has_many :responses, dependent: :destroy
    has_many :definition_versions, dependent: :destroy
    has_many :summary_versions, dependent: :destroy

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
      definition_versions.find_by(number: cursor)
    end

    def summary_document
      current_summary_version&.summary
    end

    def current_summary_version
      summary_versions.find_by(number: summary_cursor_number)
    end

    def record_summary(payload)
      summary_versions.create!(number: next_summary_number, summary: payload)
        .tap { |version| update!(summary_cursor: version.number) }
    end

    def record_definition(payload)
      definition_versions.create!(number: next_definition_number, definition: payload)
        .tap { |version| update!(definition_cursor: version.number, document: payload) }
    end

    def undoable?
      recorded_numbers.any? { |number| number < cursor }
    end

    def redoable?
      recorded_numbers.any? { |number| number > cursor }
    end

    def undo_definition
      step_to(recorded_numbers.select { |number| number < cursor }.max)
    end

    def redo_definition
      step_to(recorded_numbers.select { |number| number > cursor }.min)
    end

    def runner
      Runner.new(definition)
    end

    def summarises?
      summary_document.present?
    end

    def summary_of(state)
      Summary::Report.new(summary_document).results(Summary::Run.new(state: state, steps: steps_by_id))
    end

    private

    def steps_by_id
      Array(definition.to_h["nodes"]).index_by { |node| node["id"] }
    end

    def step_to(number)
      update!(definition_cursor: number) if number
    end

    def cursor
      definition_cursor || recorded_numbers.max
    end

    def recorded_numbers
      definition_versions.pluck(:number)
    end

    def next_definition_number
      (definition_versions.maximum(:number) || 0) + 1
    end

    def summary_cursor_number
      summary_cursor || summary_versions.pluck(:number).max
    end

    def next_summary_number
      (summary_versions.maximum(:number) || 0) + 1
    end
  end
end

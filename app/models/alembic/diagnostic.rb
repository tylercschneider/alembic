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

    def undoable?
      undoable.any?
    end

    def redoable?
      undone_changes.to_a.any?
    end

    def undo_change
      undone = undoable.last
      return unless undone

      update!(document: undone["before"], undone_changes: undone_changes.to_a + [ undone.merge("after" => document) ],
        undo_history: undo_history.to_a[0...-1], changes_since_version: changes_since_version.to_a[0...-1])
    end

    def redo_change
      redone = undone_changes.to_a.last
      return unless redone

      update!(document: redone["after"], undone_changes: undone_changes.to_a[0...-1],
        changes_since_version: changes_since_version.to_a + [ redone.except("after") ])
    end

    def publish
      create_version

      publish_version(current_definition_version)
    end

    def return_to(version)
      raise ActiveRecord::RecordNotFound unless definition_versions.exists?(version.id)
      raise OutOfService if version.out_of_service?

      update!(document: version.definition, undone_changes: [],
        changes_since_version: changes_since_version.to_a + [ returning_to(version) ])
    end

    def create_version
      record_definition(document, changes_since_version.to_a) unless versioned?

      update!(undo_history: undoable, changes_since_version: [], undone_changes: [])
    end

    def undoable
      undo_history.to_a + changes_since_version.to_a
    end

    def returning_to(version)
      { "action" => "returned", "steps" => [], "named" => [],
        "detail" => "version #{version.number}", "before" => document }
    end

    def versioned?
      document == definition
    end

    def record_definition(payload, captured = [])
      definition_versions.create!(number: next_definition_number, definition: payload,
        changes_captured: captured.map { |change| change.except("before") })
        .tap { |version| update!(definition_cursor: version.number, document: payload) }
    end

    def publish_version(version)
      raise OutOfService if version.out_of_service?
      return if live_version == version

      live_version&.update!(status: :superseded)
      version.update!(status: :live)
    end

    def retire_version(version)
      version.update!(status: :retired)
    end

    def live_version
      definition_versions.find_by(status: :live)
    end

    def live_definition
      live_version&.definition
    end

    def runner
      Runner.new(live_definition)
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

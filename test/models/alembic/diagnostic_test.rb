require "test_helper"

module Alembic
  class DiagnosticTest < ActiveSupport::TestCase
    test "reports when it is published" do
      assert Diagnostic.new(status: :published).published?
    end

    test "reports its kind" do
      assert Diagnostic.new(kind: :scored).scored?
    end

    test "is invalid without a slug" do
      assert_not Diagnostic.new(slug: nil).valid?
    end

    test "builds a runner from the version it published" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "demo" })
      diagnostic.publish

      assert_equal "demo", diagnostic.runner.slug
    end

    test "recording a definition stores it as a version" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.record_definition({ "slug" => "demo" })

      assert_equal({ "slug" => "demo" }, diagnostic.definition_versions.last.definition)
    end

    test "recording a second definition takes the next version number" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "first" })

      diagnostic.record_definition({ "slug" => "second" })

      assert_equal 2, diagnostic.definition_versions.last.number
    end

    def edited(diagnostic, entry, before)
      diagnostic.update!(document: { "entry" => entry }, undone_changes: [],
        changes_since_version: diagnostic.changes_since_version.to_a +
          [ { "action" => "updated", "steps" => [], "named" => [], "before" => before } ])
    end

    test "undoing puts back the document as it was before the change" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })

      diagnostic.undo_change

      assert_equal({ "entry" => "one" }, diagnostic.reload.document)
    end

    test "redoing puts the change back" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })
      diagnostic.undo_change

      diagnostic.redo_change

      assert_equal({ "entry" => "two" }, diagnostic.reload.document)
    end

    test "undoing records no version" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })

      assert_no_difference -> { diagnostic.definition_versions.count } do
        diagnostic.undo_change
      end
    end

    test "there is nothing to undo before anything is changed" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })

      assert_not diagnostic.undoable?
    end

    test "there is nothing to redo until something is undone" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })

      assert_not diagnostic.redoable?
    end

    test "undoing with nothing behind it leaves the document alone" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })

      diagnostic.undo_change

      assert_equal({ "entry" => "one" }, diagnostic.reload.document)
    end

    test "creating a version leaves nothing to redo but keeps what can be undone" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })
      diagnostic.undo_change

      diagnostic.create_version

      assert_not diagnostic.redoable?
    end

    test "creating a version leaves the author able to undo past it" do
      diagnostic = Diagnostic.create!(slug: "undo", document: { "entry" => "one" })
      edited(diagnostic, "two", { "entry" => "one" })

      diagnostic.create_version

      assert_predicate diagnostic, :undoable?
    end

    test "reports its current definition as the highest-numbered version" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "first" })
      diagnostic.record_definition({ "slug" => "second" })

      assert_equal({ "slug" => "second" }, diagnostic.definition)
    end

    test "upserting records the imported definition as a version" do
      Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" })

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Diagnostic.find_by(slug: "seeded").definition_versions.last.definition)
    end

    test "upserting an unchanged definition records no new version" do
      2.times { Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" }) }

      assert_equal 1, Diagnostic.find_by(slug: "seeded").definition_versions.count
    end

    test "upserts a diagnostic storing the definition keyed by its slug" do
      Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" })

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Diagnostic.find_by(slug: "seeded").definition)
    end

    test "upserting the same slug twice keeps a single diagnostic" do
      2.times { Diagnostic.upsert_definition({ "slug" => "seeded" }) }

      assert_equal 1, Diagnostic.where(slug: "seeded").count
    end

    test "can be deleted once a definition has been recorded" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("slug" => "demo")

      assert_difference -> { Diagnostic.count }, -1 do
        diagnostic.destroy!
      end
    end

    test "records a summary template as a numbered version" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.record_summary("outputs" => [ { "id" => "score" } ])

      assert_equal 1, diagnostic.summary_versions.sole.number
    end

    test "numbers a second summary template after the first" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_summary("outputs" => [])

      diagnostic.record_summary("outputs" => [ { "id" => "score" } ])

      assert_equal 2, diagnostic.summary_versions.maximum(:number)
    end

    test "reads back the summary template at its cursor" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_summary("outputs" => [ { "id" => "score" } ])

      assert_equal({ "outputs" => [ { "id" => "score" } ] }, diagnostic.summary_document)
    end

    test "recording a summary leaves the flow version untouched" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("slug" => "demo")

      assert_no_changes -> { diagnostic.reload.definition_cursor } do
        diagnostic.record_summary("outputs" => [])
      end
    end

    test "reports no summary document when none has been recorded" do
      diagnostic = Diagnostic.create!(slug: "demo")

      assert_nil diagnostic.summary_document
    end

    test "summarises from the recorded summary version" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.record_summary("outputs" => [ { "id" => "score", "type" => "weighted_sum" } ])

      assert diagnostic.summarises?
    end

    test "holds a live document that can be edited" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.update!(document: { "entry" => "a", "nodes" => [], "edges" => [] })

      assert_equal "a", diagnostic.reload.document["entry"]
    end

    test "starts with nothing changed since its last version" do
      diagnostic = Diagnostic.create!(slug: "demo")

      assert_empty diagnostic.changes_since_version.to_a
    end

    test "recording a first definition gives the diagnostic a document to edit" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.record_definition("entry" => "a", "nodes" => [], "edges" => [])

      assert_equal "a", diagnostic.reload.document["entry"]
    end

    test "creating a version records the live document" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      diagnostic.update!(document: { "entry" => "b", "nodes" => [], "edges" => [] })

      diagnostic.create_version

      assert_equal "b", diagnostic.definition_versions.order(:number).last.definition["entry"]
    end

    test "creating a version clears what had changed since the last one" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      diagnostic.update!(document: { "entry" => "b" }, changes_since_version: [ { "action" => "moved", "steps" => [ "a" ], "named" => [ "A" ] } ])

      diagnostic.create_version

      assert_empty diagnostic.reload.changes_since_version
    end

    test "creating a version twice over records only one" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("entry" => "a", "nodes" => [], "edges" => [])

      assert_no_difference -> { diagnostic.definition_versions.count } do
        diagnostic.create_version
      end
    end

    test "publishing marks the created version as the one visitors run" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      diagnostic.update!(document: { "entry" => "b", "nodes" => [], "edges" => [] })

      diagnostic.publish

      assert_equal "b", diagnostic.reload.live_version.definition["entry"]
    end

    test "a version carries the changes that produced it" do
      diagnostic = Diagnostic.create!(slug: "demo", document: { "entry" => "a" })
      diagnostic.update!(changes_since_version: [ { "action" => "added", "steps" => [ "a" ], "named" => [ "A" ] } ])

      diagnostic.create_version

      assert_equal [ "added" ], diagnostic.definition_versions.last.changes.map { |change| change["action"] }
    end

    test "returning to a version makes its content the live document" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("entry" => "first")
      first = diagnostic.definition_versions.last
      diagnostic.update!(document: { "entry" => "later" })

      diagnostic.return_to(first)

      assert_equal({ "entry" => "first" }, diagnostic.reload.document)
    end

    test "returning to a version leaves every version in place" do
      diagnostic = returnable
      first = diagnostic.definition_versions.order(:number).first

      assert_no_difference -> { diagnostic.definition_versions.count } do
        diagnostic.return_to(first)
      end
    end

    test "returning to a version leaves that version's content alone" do
      diagnostic = returnable
      first = diagnostic.definition_versions.order(:number).first

      diagnostic.return_to(first)

      assert_equal({ "entry" => "first" }, first.reload.definition)
    end

    test "returning records that the document was returned" do
      diagnostic = returnable
      first = diagnostic.definition_versions.order(:number).first

      diagnostic.return_to(first)

      assert_equal "Returned to version 1", Change.phrase(diagnostic.reload.changes_since_version.last)
    end

    test "refuses a version belonging to another diagnostic" do
      diagnostic = returnable
      stranger = Diagnostic.create!(slug: "stranger")
      stranger.record_definition("entry" => "theirs")

      assert_raises(ActiveRecord::RecordNotFound) { diagnostic.return_to(stranger.definition_versions.last) }
    end

    test "returning leaves visitors on the version they were running" do
      diagnostic = returnable
      diagnostic.publish
      running = diagnostic.live_version

      diagnostic.return_to(diagnostic.definition_versions.order(:number).first)

      assert_equal running, diagnostic.reload.live_version
    end

    test "undoing a return puts the document back" do
      diagnostic = returnable
      diagnostic.return_to(diagnostic.definition_versions.order(:number).first)

      diagnostic.undo_change

      assert_equal({ "entry" => "second" }, diagnostic.reload.document)
    end

    def returnable
      Diagnostic.create!(slug: "returnable").tap do |diagnostic|
        diagnostic.record_definition("entry" => "first")
        diagnostic.record_definition("entry" => "second")
      end
    end

    test "publishing makes the version live" do
      diagnostic = Diagnostic.create!(slug: "demo", document: { "slug" => "demo" })

      diagnostic.publish

      assert_predicate diagnostic.current_definition_version, :live?
    end

    test "publishing a newer version supersedes the one that was live" do
      diagnostic = Diagnostic.create!(slug: "demo", document: { "slug" => "demo" })
      diagnostic.publish
      first = diagnostic.current_definition_version

      diagnostic.update!(document: { "slug" => "demo", "entry" => "a" })
      diagnostic.publish

      assert_predicate first.reload, :superseded?
    end

    test "publishing the version that is already live leaves it live" do
      diagnostic = Diagnostic.create!(slug: "demo", document: { "slug" => "demo" })
      diagnostic.publish

      diagnostic.publish

      assert_predicate diagnostic.current_definition_version.reload, :live?
    end

    test "a retired version is no longer the live one" do
      diagnostic = Diagnostic.create!(slug: "demo", document: { "slug" => "demo" })
      diagnostic.publish

      diagnostic.retire_version(diagnostic.live_version)

      assert_nil diagnostic.reload.live_version
    end
  end
end

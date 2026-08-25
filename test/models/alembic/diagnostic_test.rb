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

    test "builds a runner from its current definition" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "demo" })

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

    test "undoing steps the definition back to the version before it" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })
      diagnostic.record_definition({ "slug" => "two" })

      diagnostic.undo_definition

      assert_equal({ "slug" => "one" }, diagnostic.definition)
    end

    test "redoing steps the definition forward again" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })
      diagnostic.record_definition({ "slug" => "two" })
      diagnostic.undo_definition

      diagnostic.redo_definition

      assert_equal({ "slug" => "two" }, diagnostic.definition)
    end

    test "undoing keeps every version it stepped past" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })
      diagnostic.record_definition({ "slug" => "two" })

      assert_no_difference -> { diagnostic.definition_versions.count } do
        diagnostic.undo_definition
      end
    end

    test "there is nothing to undo before the first version" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })

      assert_not diagnostic.undoable?
    end

    test "there is nothing to redo until something is undone" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })
      diagnostic.record_definition({ "slug" => "two" })

      assert_not diagnostic.redoable?
    end

    test "a fresh edit after undoing leaves nothing to redo" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.record_definition({ "slug" => "one" })
      diagnostic.record_definition({ "slug" => "two" })
      diagnostic.undo_definition

      diagnostic.record_definition({ "slug" => "three" })

      assert_not diagnostic.redoable?
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
  end
end

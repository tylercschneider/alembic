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

    test "builds a guide from its current definition" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "demo" })

      assert_equal "demo", diagnostic.to_guide.slug
    end

    test "stores guide copy and placement attributes" do
      diagnostic = Diagnostic.new(kicker: "k", headline: "h", blurb: "b", start_label: "s", resolver_key: "r")

      assert_equal [ "k", "h", "b", "s", "r" ], [ diagnostic.kicker, diagnostic.headline, diagnostic.blurb, diagnostic.start_label, diagnostic.resolver_key ]
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

    test "reports the version before the current one" do
      diagnostic = Diagnostic.create!(slug: "undo")
      first = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "one" })
      diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "two" })

      assert_equal first, diagnostic.reload.previous_definition_version
    end

    test "reports no earlier version when only one has been recorded" do
      diagnostic = Diagnostic.create!(slug: "undo")
      diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "one" })

      assert_nil diagnostic.reload.previous_definition_version
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
  end
end

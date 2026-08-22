require "test_helper"

module Alembic
  class ResponseTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = diagnostic.responses.create!(definition_version: version)

      assert_equal diagnostic, response.diagnostic
    end

    test "pins to the diagnostic's current definition version when started" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = Response.start(diagnostic)

      assert_equal version, response.definition_version
    end

    test "pins to the newer version when started after a recompile" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      recompiled = diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      response = Response.start(diagnostic.reload)

      assert_equal recompiled, response.definition_version
    end

    test "leaves an earlier response pinned to the version it began on" do
      diagnostic = Diagnostic.create!(slug: "demo")
      began_on = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      response = Response.start(diagnostic)

      diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      assert_equal began_on, response.reload.definition_version
    end

    test "takes an owner of any type the host application supplies" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      owner = diagnostic.domains.create!(key: "governance", name: "Governance")

      response = diagnostic.responses.create!(definition_version: version, owner: owner)

      assert_equal owner, response.reload.owner
    end

    test "is valid with no owner at all" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = diagnostic.responses.build(definition_version: version, owner: nil)

      assert response.valid?
    end

    test "records an answer into its stored answers" do
      response = Response.start(diagnostic_with_a_version)

      response.record_answer(:pick, "a")

      assert_equal({ pick: "a" }, response.answers)
    end

    private

    def diagnostic_with_a_version
      Diagnostic.create!(slug: "demo").tap do |diagnostic|
        diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      end
    end
  end
end

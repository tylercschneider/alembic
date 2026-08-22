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
  end
end

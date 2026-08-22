require "test_helper"

module Alembic
  class ResponseTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = diagnostic.responses.create!(definition_version: version)

      assert_equal diagnostic, response.diagnostic
    end
  end
end

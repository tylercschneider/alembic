require "test_helper"

module Alembic
  class SummaryVersionTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

      assert_equal diagnostic, version.diagnostic
    end
  end
end

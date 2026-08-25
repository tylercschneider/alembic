require "test_helper"

module Alembic
  class SummaryVersionTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

      assert_equal diagnostic, version.diagnostic
    end

    test "is invalid when the diagnostic already has that version number" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

      duplicate = diagnostic.summary_versions.build(number: 1, summary: { "outputs" => [] })

      assert_not duplicate.valid?
    end
  end
end

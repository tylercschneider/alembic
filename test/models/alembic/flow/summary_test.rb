require "test_helper"

module Alembic
  module Flow
    class SummaryTest < ActiveSupport::TestCase
      test "is invalid when the diagnostic already has that version number" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

        duplicate = diagnostic.summary_versions.build(number: 1, summary: { "outputs" => [] })

        assert_not duplicate.valid?
      end

      test "refuses to be updated once persisted" do
        diagnostic = Diagnostic.create!(slug: "demo")
        version = diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

        assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(summary: { "outputs" => [ { "id" => "x" } ] }) }
      end

      test "is destroyed along with its diagnostic" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.summary_versions.create!(number: 1, summary: { "outputs" => [] })

        assert_difference -> { Summary.count }, -1 do
          diagnostic.destroy!
        end
      end
    end
  end
end

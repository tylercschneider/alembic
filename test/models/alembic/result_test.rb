require "test_helper"

module Alembic
  class ResultTest < ActiveSupport::TestCase
    test "reports its slot" do
      assert Result.new(slot: :tier).tier?
    end

    test "orders a diagnostic's results by position" do
      diagnostic = Diagnostic.create!(slug: "result-ordering", kind: :guide, status: :draft)
      diagnostic.results.create!(slot: :tier, key: "b", position: 2)
      diagnostic.results.create!(slot: :tier, key: "a", position: 1)

      assert_equal [ "a", "b" ], diagnostic.results.ordered.map(&:key)
    end

    test "is invalid without a key" do
      result = Result.new(diagnostic: alembic_diagnostics(:stats_ladder), key: nil)

      assert_not result.valid?
    end
  end
end

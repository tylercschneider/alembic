require "test_helper"

module Alembic
  class ConditionTest < ActiveSupport::TestCase
    test "is satisfied when the dependent answer is among its values" do
      condition = Condition.new(depends_on: "need", values: [ "now", "trend" ])

      assert condition.satisfied_by?({ "need" => "now" })
    end
  end
end

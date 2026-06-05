require "test_helper"

module Alembic
  class ConditionTest < ActiveSupport::TestCase
    test "is satisfied when the answer matches one of its options" do
      condition = alembic_conditions(:read_needs_current_state)

      assert condition.satisfied_by?({ "need" => "now" })
    end

    test "is not satisfied when the answer matches none of its options" do
      condition = alembic_conditions(:read_needs_current_state)

      assert_not condition.satisfied_by?({ "need" => "rates" })
    end
  end
end

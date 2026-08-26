require "test_helper"

module Alembic
  class FlowTest < ActiveSupport::TestCase
    test "refuses a check it does not ship" do
      assert_raises(Flow::UnknownCheck) { Flow.check(:invented) }
    end
  end
end

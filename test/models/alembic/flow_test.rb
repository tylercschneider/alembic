require "test_helper"

module Alembic
  class FlowTest < ActiveSupport::TestCase
    test "draws a step with the template it ships when nothing replaces it" do
      assert_equal "alembic/flow/steps/choosing", Flow.drawing
    end

    test "refuses a check it does not ship" do
      assert_raises(Flow::UnknownCheck) { Flow.check(:invented) }
    end
  end
end

require "test_helper"

module Alembic
  class FlowTest < ActiveSupport::TestCase
    test "draws a step with the template it ships when nothing replaces it" do
      assert_equal "alembic/flow/steps/choosing", Flow.drawing
    end

    test "draws every step with the template a host puts in its place" do
      Flow.draws_with("host/steps/panel")

      assert_equal "host/steps/panel", Flow.drawing
    ensure
      Flow.draws_with(nil)
    end

    test "refuses a check it does not ship" do
      assert_raises(Flow::UnknownCheck) { Flow.check(:invented) }
    end
  end
end

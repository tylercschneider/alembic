require "test_helper"

module Alembic
  module Flow
    class ReferencesTest < ActiveSupport::TestCase
      test "finds the step named in a configuration value" do
        assert_equal [ "ask" ], References.of("prompt" => "Repeat {{ask}} back")
      end

      test "finds nothing in a configuration that names no step" do
        assert_empty References.of("prompt" => "Nothing to see")
      end

      test "finds a step named inside a nested configuration value" do
        assert_equal [ "ask" ], References.of("answers" => [ { "label" => "Echo {{ask}}" } ])
      end
    end
  end
end

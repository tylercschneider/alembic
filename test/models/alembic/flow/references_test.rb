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
    end
  end
end

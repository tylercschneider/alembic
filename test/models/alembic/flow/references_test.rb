require "test_helper"

module Alembic
  module Flow
    class ReferencesTest < ActiveSupport::TestCase
      test "finds the step named in a configuration value" do
        assert_equal [ "ask" ], References.of("prompt" => "Repeat {{ask}} back")
      end
    end
  end
end

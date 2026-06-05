require "test_helper"

class AlembicTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Alembic::VERSION
  end

  test "reads a bundled definition by slug" do
    assert_equal "stats-system-ladder", Alembic.bundled_definition("stats-system-ladder")["slug"]
  end
end

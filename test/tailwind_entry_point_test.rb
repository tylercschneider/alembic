require "test_helper"

class TailwindEntryPointTest < ActiveSupport::TestCase
  test "the engine ships a Tailwind entry point where a host build looks for it" do
    assert_path_exists entry_point
  end

  private

  def entry_point
    Alembic::Engine.root.join("app/assets/tailwind/#{Alembic::Engine.engine_name}/engine.css")
  end
end

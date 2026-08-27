require "test_helper"

module Alembic
  class HostRouteContextTest < ActionDispatch::IntegrationTest
    test "engine controllers inherit the host's application controller" do
      assert_includes Manage::BaseController.ancestors, ::ApplicationController
    end

    test "a bare engine route helper does not resolve to the engine's route in a builder view" do
      get alembic.manage_flows_path

      assert_not_equal alembic.manage_flows_path, @controller.view_context.manage_flows_path
    end
  end
end

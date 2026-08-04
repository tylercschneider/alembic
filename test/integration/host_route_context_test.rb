require "test_helper"

module Alembic
  class HostRouteContextTest < ActionDispatch::IntegrationTest
    test "engine controllers inherit the host's application controller" do
      assert_includes Manage::BaseController.ancestors, ::ApplicationController
    end
  end
end

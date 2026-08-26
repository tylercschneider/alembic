require "test_helper"

module Alembic
  class CanvasAssetTest < ActionDispatch::IntegrationTest
    test "the canvas bundle is served by the asset pipeline" do
      get ActionController::Base.helpers.asset_path("alembic/canvas.js")

      assert_response :success
    end
  end
end

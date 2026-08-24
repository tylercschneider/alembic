require "test_helper"

module Alembic
  class CanvasAssetTest < ActionDispatch::IntegrationTest
    test "the canvas bundle is served by the asset pipeline" do
      get ActionController::Base.helpers.asset_path("alembic/canvas.js")

      assert_response :success
    end

    test "the canvas stylesheet is served by the asset pipeline" do
      get ActionController::Base.helpers.asset_path("alembic/canvas.css")

      assert_response :success
    end

    test "the canvas bundle carries the flow library it was built from" do
      bundle = Engine.root.join("app/assets/builds/alembic/canvas.js").read

      assert_includes bundle, "react-flow"
    end
  end
end

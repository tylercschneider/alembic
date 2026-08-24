require "test_helper"

module Alembic
  class CanvasAssetTest < ActionDispatch::IntegrationTest
    test "the canvas bundle is served by the asset pipeline" do
      get ActionController::Base.helpers.asset_path("alembic/canvas.js")

      assert_response :success
    end

    test "the canvas bundle carries the library it was built from" do
      bundle = Engine.root.join("app/assets/builds/alembic/canvas.js").read

      assert_includes bundle, "react.transitional.element"
    end
  end
end

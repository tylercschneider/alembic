require "test_helper"

module Alembic
  class SavedSessionsTest < ActionDispatch::IntegrationTest
    test "starting a saved session sends the visitor to its durable URL" do
      post alembic.diagnostic_responses_path("db-guide")

      assert_redirected_to alembic.response_path(Response.last)
    end
  end
end

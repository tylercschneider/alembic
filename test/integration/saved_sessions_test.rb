require "test_helper"

module Alembic
  class SavedSessionsTest < ActionDispatch::IntegrationTest
    test "starting a saved session sends the visitor to its durable URL" do
      post alembic.diagnostic_responses_path("db-guide")

      assert_redirected_to alembic.response_path(Response.last)
    end

    test "a saved session renders the question it is waiting on" do
      response = Response.start(alembic_diagnostics(:db_guide))

      get alembic.response_path(response)

      assert_select "legend", text: /Pick one option/
    end
  end
end

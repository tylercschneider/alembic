require "test_helper"

module Alembic
  class HostLayoutTest < ActionDispatch::IntegrationTest
    test "the visitor guide renders inside the host application layout" do
      get alembic.diagnostic_path(alembic_diagnostics(:business_scorecard).slug)

      assert_select "meta[name=application-name][content=Dummy]"
    end
  end
end

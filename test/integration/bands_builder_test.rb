require "test_helper"

module Alembic
  class BandsBuilderTest < ActionDispatch::IntegrationTest
    test "the bands index lists the diagnostic's bands" do
      diagnostic = Diagnostic.create!(slug: "bands")
      diagnostic.bands.create!(ceiling: 10, name: "Starter", description: "Just beginning.")

      get alembic.manage_diagnostic_bands_path(diagnostic)

      assert_includes response.body, "Starter"
    end
  end
end

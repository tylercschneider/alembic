require "test_helper"

module Alembic
  class BandsBuilderTest < ActionDispatch::IntegrationTest
    test "the bands index lists the diagnostic's bands" do
      diagnostic = Diagnostic.create!(slug: "bands")
      diagnostic.bands.create!(ceiling: 10, name: "Starter", description: "Just beginning.")

      get alembic.manage_diagnostic_bands_path(diagnostic)

      assert_includes response.body, "Starter"
    end

    test "the bands index has an add-band form" do
      diagnostic = Diagnostic.create!(slug: "bands")

      get alembic.manage_diagnostic_bands_path(diagnostic)

      assert_select "form[action=?]", alembic.manage_diagnostic_bands_path(diagnostic)
    end

    test "an added band persists its ceiling" do
      diagnostic = Diagnostic.create!(slug: "bands")

      post alembic.manage_diagnostic_bands_path(diagnostic), params: { band: { name: "Starter", ceiling: 10 } }

      assert_equal 10, diagnostic.bands.sole.ceiling
    end

    test "an added band persists its description" do
      diagnostic = Diagnostic.create!(slug: "bands")

      post alembic.manage_diagnostic_bands_path(diagnostic), params: { band: { name: "Starter", description: "Just beginning." } }

      assert_equal "Just beginning.", diagnostic.bands.sole.description
    end

    test "the bands index links each band to its edit form" do
      diagnostic = Diagnostic.create!(slug: "bands")
      band = diagnostic.bands.create!(ceiling: 10, name: "Starter")

      get alembic.manage_diagnostic_bands_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_band_path(diagnostic, band)
    end

    test "the band edit form prefills the band's name" do
      diagnostic = Diagnostic.create!(slug: "bands")
      band = diagnostic.bands.create!(ceiling: 10, name: "Starter")

      get alembic.edit_manage_diagnostic_band_path(diagnostic, band)

      assert_select "input[name=?][value=?]", "band[name]", "Starter"
    end

    test "updating a band saves the name" do
      diagnostic = Diagnostic.create!(slug: "bands")
      band = diagnostic.bands.create!(ceiling: 10, name: "old")

      patch alembic.manage_diagnostic_band_path(diagnostic, band), params: { band: { name: "Starter" } }

      assert_equal "Starter", band.reload.name
    end

    test "destroying a band removes it from the diagnostic" do
      diagnostic = Diagnostic.create!(slug: "bands")
      band = diagnostic.bands.create!(ceiling: 10, name: "Starter")

      assert_difference -> { diagnostic.bands.count }, -1 do
        delete alembic.manage_diagnostic_band_path(diagnostic, band)
      end
    end
  end
end

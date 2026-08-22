require "test_helper"
require Rails.root.join("../../db/migrate/20260822120100_backfill_alembic_definition_versions.rb")

class BackfillAlembicDefinitionVersionsTest < ActiveSupport::TestCase
  test "records an existing definition as version 1" do
    diagnostic = Alembic::Diagnostic.create!(slug: "demo", definition: { "slug" => "demo" })

    ActiveRecord::Migration.suppress_messages { BackfillAlembicDefinitionVersions.new.up }

    assert_equal({ "slug" => "demo" }, diagnostic.definition_versions.find_by(number: 1).definition)
  end
end

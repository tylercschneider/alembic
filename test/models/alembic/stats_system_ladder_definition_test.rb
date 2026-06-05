require "test_helper"

module Alembic
  class StatsSystemLadderDefinitionTest < ActiveSupport::TestCase
    def reference
      StatsSystemLadder.build
    end

    def loaded
      DefinitionLoader.new(definition).build
    end

    def definition
      JSON.parse(File.read(Alembic::Engine.root.join("lib/alembic/definitions/stats_system_ladder.json")))
    end

    test "matches the reference slug" do
      assert_equal reference.slug, loaded.slug
    end
  end
end

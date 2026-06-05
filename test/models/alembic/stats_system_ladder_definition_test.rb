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

    test "matches the reference intro copy" do
      assert_equal [ reference.kicker, reference.headline, reference.blurb, reference.start_label ],
        [ loaded.kicker, loaded.headline, loaded.blurb, loaded.start_label ]
    end

    test "matches the reference question ids in order" do
      assert_equal reference.questions.map(&:id), loaded.questions.map(&:id)
    end

    test "matches the reference question options" do
      assert_equal reference.questions.map(&:options), loaded.questions.map(&:options)
    end

    BRANCH_PATHS = [
      {},
      { need: "now" },
      { need: "trend" },
      { need: "rates" },
      { need: "rates", loss: "money" },
      { need: "audit" }
    ].freeze

    test "branches identically to the reference across answer paths" do
      assert_equal BRANCH_PATHS.map { |answers| reference.next_question(answers)&.id },
        BRANCH_PATHS.map { |answers| loaded.next_question(answers)&.id }
    end

    test "matches the reference warnings" do
      assert_equal reference.warnings, loaded.warnings
    end

    test "matches every reference tier node" do
      assert_equal (1..5).map { |number| reference.tier(number) }, (1..5).map { |number| loaded.tier(number) }
    end

    LEVEL_KEYS = [ :l12, :l3, :l4, :l0 ].freeze

    test "matches every reference level node" do
      assert_equal LEVEL_KEYS.map { |key| reference.level(key) }, LEVEL_KEYS.map { |key| loaded.level(key) }
    end

    PLACEMENT_PATHS = [
      { need: "now", read: "light" },
      { need: "now", read: "hot" },
      { need: "trend" },
      { need: "rates", loss: "insight", origin: "app" },
      { need: "rates", loss: "money", origin: "app" },
      { need: "rates", loss: "money", origin: "anon" },
      { need: "rates", loss: "insight", origin: "anon" },
      { need: "rates", loss: "insight", origin: "svc" },
      { need: "audit", origin: "app" },
      { need: "audit", origin: "anon" }
    ].freeze

    test "places identically to the reference across answer paths" do
      assert_equal PLACEMENT_PATHS.map { |answers| reference.place(answers) },
        PLACEMENT_PATHS.map { |answers| loaded.place(answers) }
    end
  end
end

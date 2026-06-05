require "test_helper"

module Alembic
  class StatsSystemLadderTest < ActiveSupport::TestCase
    def guide
      Guide.find("stats-system-ladder")
    end

    test "registers the stats system ladder guide by slug" do
      assert_equal "stats-system-ladder", guide.slug
    end

    test "opens by asking what the most advanced need is" do
      assert_equal :need, guide.next_question({}).id
    end

    test "offers the four need values the resolver places on" do
      assert_equal [ "now", "trend", "rates", "audit" ], guide.next_question({}).options.map(&:value)
    end

    test "a current-state need then asks about read pressure" do
      assert_equal :read, guide.next_question({ need: "now" }).id
    end

    test "a rates need then asks about loss impact" do
      assert_equal :loss, guide.next_question({ need: "rates" }).id
    end

    test "after loss a rates need asks where events come from" do
      assert_equal :origin, guide.next_question({ need: "rates", loss: "money" }).id
    end

    test "an audit need skips loss and asks origin directly" do
      assert_equal :origin, guide.next_question({ need: "audit" }).id
    end

    test "places a money-grade in-process rates path on the outbox level" do
      assert_equal :l3, guide.place({ need: "rates", loss: "money", origin: "app" }).level
    end

    test "carries intro copy for the landing page" do
      assert guide.headline.present?
    end

    test "names the tier a placement lands on" do
      assert_equal "Event log + rollups", guide.tier(4).name
    end

    test "names the event level a placement lands on" do
      assert_equal "Outbox · durable", guide.level(:l3).name
    end

    test "supplies copy for every warning the resolver can emit" do
      assert [ :insight_pairing, :money_pairing, :sourcing_floor, :money_vs_lossy ].all? { |warning| guide.warning_text(warning).present? }
    end

    test "every tier carries build steps and explanatory content" do
      assert (1..5).all? { |number| guide.tier(number).build_steps.any? && guide.tier(number).captures.present? }
    end

    test "every event level carries build steps and explanatory content" do
      assert [ :l12, :l3, :l4, :l0 ].all? { |key| guide.level(key).build_steps.any? && guide.level(key).captures.present? }
    end
  end
end

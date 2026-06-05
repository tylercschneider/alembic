require "test_helper"

module Alembic
  class StatsLadderPlacementTest < ActiveSupport::TestCase
    def place(answers)
      StatsLadderPlacement.new.call(answers)
    end

    test "current-state need places on tier 1" do
      assert_equal 1, place({ need: "now" }).tier
    end

    test "a hot read on current state bumps to tier 2" do
      assert_equal 2, place({ need: "now", read: "hot" }).tier
    end

    test "trend need places on tier 3" do
      assert_equal 3, place({ need: "trend" }).tier
    end

    test "rates need places on tier 4" do
      assert_equal 4, place({ need: "rates", loss: "insight", origin: "app" }).tier
    end

    test "audit need places on tier 5" do
      assert_equal 5, place({ need: "audit", origin: "app" }).tier
    end

    test "tiers below four carry no event level" do
      assert_nil place({ need: "trend" }).level
    end

    test "a tolerable loss grades insight" do
      assert_equal :insight, place({ need: "rates", loss: "insight", origin: "app" }).grade
    end

    test "a money-impacting loss grades money" do
      assert_equal :money, place({ need: "rates", loss: "money", origin: "app" }).grade
    end

    test "anonymous origin lands on the telemetry sink level" do
      assert_equal :l0, place({ need: "rates", loss: "insight", origin: "anon" }).level
    end

    test "money-grade anonymous events route to the durable outbox, not the lossy sink" do
      assert_equal :l3, place({ need: "rates", loss: "money", origin: "anon" }).level
    end

    test "money-grade anonymous events are flagged as a conflict" do
      assert_not place({ need: "rates", loss: "money", origin: "anon" }).warning_ok
    end

    test "money-grade anonymous events name the money-versus-lossy warning" do
      assert_equal :money_vs_lossy, place({ need: "rates", loss: "money", origin: "anon" }).warning
    end

    test "cross-service origin lands on the broker level" do
      assert_equal :l4, place({ need: "rates", loss: "insight", origin: "svc" }).level
    end

    test "money-grade in-process events require the durable outbox level" do
      assert_equal :l3, place({ need: "rates", loss: "money", origin: "app" }).level
    end

    test "insight-grade in-process events stay on the in-process level" do
      assert_equal :l12, place({ need: "rates", loss: "insight", origin: "app" }).level
    end

    test "an insight pairing names the insight-pairing note" do
      assert_equal :insight_pairing, place({ need: "rates", loss: "insight", origin: "app" }).warning
    end

    test "a money pairing on a durable level names the money-pairing note" do
      assert_equal :money_pairing, place({ need: "rates", loss: "money", origin: "app" }).warning
    end

    test "a tier-four pairing is flagged as a sound match" do
      assert place({ need: "rates", loss: "insight", origin: "app" }).warning_ok
    end

    test "event sourcing forces a money grade" do
      assert_equal :money, place({ need: "audit", origin: "app" }).grade
    end

    test "event sourcing names the durable-floor warning" do
      assert_equal :sourcing_floor, place({ need: "audit", origin: "app" }).warning
    end

    test "event sourcing is not flagged as a carefree match" do
      assert_not place({ need: "audit", origin: "app" }).warning_ok
    end

    test "event sourcing lifts a lossy anonymous sink up to the outbox floor" do
      assert_equal :l3, place({ need: "audit", origin: "anon" }).level
    end
  end
end

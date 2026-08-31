require "test_helper"

module Alembic
  module Flow
    class ProgressTest < ActiveSupport::TestCase
      def flow(persists)
        Flow::Definition.create!(slug: "p-#{persists}", persists: persists).tap do |built|
          built.record_definition(flowing({ "slug" => "p", "entry" => "a",
            "nodes" => [ { "id" => "a", "type" => "question", "question" => "A?", "answers" => [ { "value" => "yes" } ] } ] }))
          built.publish
        end
      end

      test "a kept run is already stored when the flow finishes" do
        run = Flow::Run.start(flow(:each_step))

        assert_equal run, Progress.for(run.flow, run: run).finish({ a: "yes" })
      end

      test "a flow keeping nothing stores nothing when the flow finishes" do
        assert_nil Progress.for(flow(:unsaved), answers: { a: "yes" }).finish({ a: "yes" })
      end

      test "a flow keeping a run only at the end stores it when the flow finishes" do
        progress = Progress.for(flow(:on_finish), answers: { a: "yes" })

        assert_equal({ a: "yes" }, progress.finish({ a: "yes" }).recorded)
      end

      test "a kept run drops the last answer stored against it" do
        run = Flow::Run.start(flow(:each_step))
        run.record(:a, "yes")
        Progress.for(run.flow, run: run).discard_last

        assert_empty run.reload.recorded
      end

      test "a loose run drops the last answer on the path it walked" do
        progress = Progress.for(flow(:unsaved), answers: { a: "yes" })
        progress.discard_last

        assert_empty progress.recorded
      end

      test "a kept run stores a new answer against itself" do
        run = Flow::Run.start(flow(:each_step))
        Progress.for(run.flow, run: run).record(:a, "yes")

        assert_equal({ a: "yes" }, run.reload.recorded)
      end

      test "a loose run carries a new answer without storing it" do
        progress = Progress.for(flow(:unsaved), answers: { a: "yes" })
        progress.record(:b, "no")

        assert_equal({ a: "yes", b: "no" }, progress.recorded)
      end

      test "a flow keeping every step reads the answers stored against its run" do
        run = Flow::Run.start(flow(:each_step))
        run.record(:a, "yes")

        assert_equal({ a: "yes" }, Progress.for(run.flow, run: run).recorded)
      end

      test "a flow keeping nothing reads the answers it was handed" do
        progress = Progress.for(flow(:unsaved), answers: { a: "yes" })

        assert_equal({ a: "yes" }, progress.recorded)
      end
    end
  end
end

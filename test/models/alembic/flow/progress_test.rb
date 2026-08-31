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

      test "a flow keeping nothing reads the answers it was handed" do
        progress = Progress.for(flow(:unsaved), answers: { a: "yes" })

        assert_equal({ a: "yes" }, progress.recorded)
      end
    end
  end
end

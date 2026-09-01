require "test_helper"

module Alembic
  class StepTemplatesTest < ActionDispatch::IntegrationTest
    def notifying
      @notifying ||= Flow::Definition.create!(slug: "notifying").tap do |flow|
        flow.record_definition(flowing({ "slug" => "notifying", "entry" => "tell",
          "nodes" => [ { "id" => "tell", "type" => "notify", "message" => "We will be in touch" } ] }))
        flow.publish
      end
    end

    def asking
      @asking ||= Flow::Definition.create!(slug: "asking").tap do |flow|
        flow.record_definition(flowing({ "slug" => "asking", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "question" => "Budget?",
                         "answers" => [ { "value" => "low" } ] } ] }))
        flow.publish
      end
    end

    test "draws every step with the template a host puts in place of the shipped one" do
      Flow.draws_with("steps/everything")

      get alembic.flow_step_path(asking.slug)

      assert_select "[data-drawn-by=?]", "everything"
    ensure
      Flow.draws_with(nil)
    end

    test "draws a step with the template its own type names" do
      get alembic.flow_step_path(notifying.slug)

      assert_select "[data-drawn-by=?]", "notify"
    end
  end
end

require "test_helper"

module Alembic
  class StepProcessTest < ActionDispatch::IntegrationTest
    def stamping
      @stamping ||= Flow::Definition.create!(slug: "stamping", persists: :each_step).tap do |flow|
        flow.record_definition(flowing({ "slug" => "stamping", "entry" => "mark",
          "nodes" => [ { "id" => "mark", "type" => "stamp", "with" => "seen" },
                       { "id" => "after", "type" => "question", "question" => "And then?",
                         "answers" => [ { "value" => "ok" } ] } ],
          "edges" => [ { "from" => "mark", "to" => "after" } ] }))
        flow.publish
      end
    end

    def loose
      @loose ||= Flow::Definition.create!(slug: "loosely").tap do |flow|
        flow.record_definition(flowing({ "slug" => "loosely", "entry" => "mark",
          "nodes" => [ { "id" => "mark", "type" => "stamp", "with" => "seen" },
                       { "id" => "after", "type" => "question", "question" => "And then?",
                         "answers" => [ { "value" => "ok" } ] } ],
          "edges" => [ { "from" => "mark", "to" => "after" } ] }))
        flow.publish
      end
    end

    test "carries a process result forward so a flow keeping nothing does not run it twice" do
      get alembic.flow_step_path(loose.slug)

      assert_select "input[name=?][value=?]", "answers[mark]", "seen"
    end

    test "records what a step's process returned against the run" do
      run = Flow::Run.start(stamping)

      get alembic.run_path(run)

      assert_equal "seen", run.reload.recorded[:mark]
    end

    test "walks past a step that acts to the next step that asks" do
      get alembic.run_path(Flow::Run.start(stamping))

      assert_select "legend", text: /And then\?/
    end
  end
end

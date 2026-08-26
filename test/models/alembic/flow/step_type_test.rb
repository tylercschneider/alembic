require "test_helper"

module Alembic
  module Flow
    class StepTypeTest < ActiveSupport::TestCase
      def node_testing(id)
        Node.new(id: "branch", type: "condition", config: { "answer" => id })
      end

      test "carries the behaviour it declares" do
        step_type = StepType.define(:agent) { process { |node, state| { "out" => state["in"] } } }

        assert_equal({ "out" => 1 }, step_type.process(node_testing("a"), { "in" => 1 }))
      end

      test "contributes nothing when it declares no behaviour" do
        step_type = StepType.define(:agent) { }

        assert_nil step_type.process(node_testing("a"), {})
      end

      test "carries the routing it declares separately from its behaviour" do
        step_type = StepType.define(:branch) do
          outputs :yes, :no
          route { |node, state| state["ok"] ? :yes : :no }
        end

        assert_equal :no, step_type.route(node_testing("a"), { "ok" => false })
      end

      test "chooses no port when it declares no routing" do
        step_type = StepType.define(:agent) { }

        assert_nil step_type.route(node_testing("a"), {})
      end

      test "derives its required predecessors from a node's configuration" do
        step_type = StepType.define(:condition) { requires { |node| [ node.config["answer"] ] } }

        assert_equal [ "a" ], step_type.requirements_for(node_testing("a"))
      end

      test "requires nothing when it declares no requirements" do
        step_type = StepType.define(:agent) { }

        assert_empty step_type.requirements_for(node_testing("a"))
      end

      test "awaits external input when it declares so" do
        step_type = StepType.define(:question) { awaits_input }

        assert_predicate step_type, :awaits_input?
      end

      test "does not await external input by default" do
        step_type = StepType.define(:agent) { }

        assert_not_predicate step_type, :awaits_input?
      end

      test "declares named output ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_equal [ :yes, :no ], step_type.ports
      end

      test "has a single unnamed output when it declares no ports" do
        step_type = StepType.define(:agent) { }

        assert_predicate step_type, :single_output?
      end

      test "does not have a single unnamed output once it names ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_not_predicate step_type, :single_output?
      end

      test "declares a setting naming a step that comes before it" do
        step_type = StepType.define(:branch) { setting :step, type: :previous_step }

        assert_equal :previous_step, step_type.fields[:step]
      end

      test "declares a setting whose choices come from the step another setting names" do
        step_type = StepType.define(:branch) do
          setting :step, type: :previous_step
          setting :answer, from: :step
        end

        assert_equal :step, step_type.drawn_from[:answer]
      end

      test "declares what a later step may choose from it" do
        step_type = StepType.define(:ask) { offers { |node| node.config["answers"] } }
        node = Node.new(id: "q", type: "ask", config: { "answers" => [ { "value" => "high" } ] })

        assert_equal [ { "value" => "high" } ], step_type.offerings_for(node)
      end

      test "can declare which field names an instance of it" do
        step_type = StepType.define(:ask) { setting :text, type: :string; names_by :text }

        assert_equal :text, step_type.naming_field
      end

      test "names an instance by nothing unless it says so" do
        step_type = StepType.define(:branch) { setting :answer, type: :string }

        assert_nil step_type.naming_field
      end

      test "declares a setting holding a repeating group" do
        step_type = StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer } }

        assert_equal :list, step_type.fields[:options]
      end

      test "carries what each record in the list holds" do
        step_type = StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer } }

        assert_equal({ value: :string, weight: :integer }, step_type.record_fields[:options])
      end

      test "refuses a list of records that does not say what a record holds" do
        assert_raises UnknownFieldType do
          StepType.define(:ask) { setting :options, type: :list }
        end
      end

      test "refuses a record holding a type outside the vocabulary" do
        assert_raises UnknownFieldType do
          StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :wormhole } }
        end
      end

      test "carries the fields it declares" do
        step_type = StepType.define(:agent) { setting :prompt, type: :string }

        assert_equal({ prompt: :string }, step_type.fields)
      end

      test "refuses a field type outside the vocabulary" do
        assert_raises UnknownFieldType do
          StepType.define(:agent) { setting :prompt, type: :wormhole }
        end
      end

      test "carries the label it was given" do
        step_type = StepType.define(:agent) { step_name "Agent call" }

        assert_equal "Agent call", step_type.step_name
      end

      test "falls back to its identifier when no label is given" do
        step_type = StepType.define(:agent) { }

        assert_equal "agent", step_type.step_name
      end

      test "carries the identifier it was defined with" do
        step_type = StepType.define(:agent) { step_name "Agent call" }

        assert_equal :agent, step_type.id
      end

      test "declares a configurable value with setting" do
        step_type = StepType.define(:probe) { setting :prompt, type: :string }

        assert_equal({ prompt: :string }, step_type.fields)
      end

      test "refuses a setting whose type it does not know" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :prompt, type: :nonsense } }
      end

      test "refuses a repeating group that does not say what an entry holds" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :answers, type: :records } }
      end

      test "refuses the text type in favour of string" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :prompt, type: :text } }
      end

      test "refuses the number type in favour of integer and float" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :weight, type: :number } }
      end

      test "refuses an unknown type inside a repeating group" do
        assert_raises(UnknownFieldType) do
          StepType.define(:probe) { setting(:answers, type: :list) { setting :weight, type: :number } }
        end
      end

      test "declares what each entry of a list holds" do
        step_type = StepType.define(:ask) do
          setting :answers, type: :list do
            setting :value, type: :string
            setting :weight, type: :integer
          end
        end

        assert_equal({ value: :string, weight: :integer }, step_type.record_fields[:answers])
      end

      test "declares the name a step type is known by" do
        step_type = StepType.define(:ask) { step_name "Question" }

        assert_equal "Question", step_type.step_name
      end

      test "labels a setting after its key" do
        step_type = StepType.define(:ask) { setting :question, type: :string }

        assert_equal "Question", step_type.labels[:question]
      end

      test "prefers a label a setting states for itself" do
        step_type = StepType.define(:ask) { setting :tag, type: :string, label: "Grouping tag" }

        assert_equal "Grouping tag", step_type.labels[:tag]
      end

      test "stores an integer setting as a number" do
        step_type = StepType.define(:ask) { setting :weight, type: :integer }

        assert_equal({ "weight" => 5 }, step_type.coerce("weight" => "5"))
      end

      test "stores a list entry's integer as a number" do
        step_type = StepType.define(:ask) do
          setting :options, type: :list do
            setting :value, type: :string
            setting :weight, type: :integer
          end
        end

        coerced = step_type.coerce("options" => [ { "value" => "low", "weight" => "3" } ])

        assert_equal 3, coerced["options"].first["weight"]
      end

      test "refuses a multi select that offers no options" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :channels, type: :multi_select } }
      end

      test "objects to a value outside the options it offers" do
        step_type = StepType.define(:probe) { setting :channels, type: :multi_select, options: %w[email sms] }

        assert_equal [ "Channels does not offer post" ], step_type.objections("channels" => %w[email post])
      end

      test "objects to more choices than its limit allows" do
        step_type = StepType.define(:probe) { setting :channels, type: :multi_select, options: %w[a b c], limit: 2 }

        assert_equal [ "Channels takes at most 2" ], step_type.objections("channels" => %w[a b c])
      end

      test "objects to more list entries than its limit allows" do
        step_type = StepType.define(:probe) do
          setting :answers, type: :list, limit: 1 do
            setting :value, type: :string
          end
        end

        assert_equal [ "Answers takes at most 1" ], step_type.objections("answers" => [ { "value" => "a" }, { "value" => "b" } ])
      end

      test "objects with the message a check returns" do
        step_type = StepType.define(:probe) do
          setting :channels, type: :multi_select, options: %w[a b],
            check: ->(chosen) { "Channels needs at least one" if chosen.empty? }
        end

        assert_equal [ "Channels needs at least one" ], step_type.objections("channels" => [])
      end

      test "accepts a value its check returns nothing for" do
        step_type = StepType.define(:probe) do
          setting :channels, type: :multi_select, options: %w[a b],
            check: ->(chosen) { "Channels needs at least one" if chosen.empty? }
        end

        assert_empty step_type.objections("channels" => %w[a])
      end
    end
  end
end

module Alembic
  class Engine < ::Rails::Engine
    isolate_namespace Alembic

    initializer "alembic.step_types" do |app|
      app.config.to_prepare do
        Alembic::Flow::Start.register
        Alembic::Flow::Terminal.register

        Alembic::Steps::Question.register
        Alembic::Steps::Condition.register
        Alembic::Steps::Switch.register

        Alembic::Flow.check(:unrouted_value)
        Alembic::Flow.check(:unfollowed_path)
        Alembic::Flow.check(:dead_end)
        Alembic::Outputs::WeightedSum.register
        Alembic::Outputs::Percentage.register
        Alembic::Outputs::Grouped.register
        Alembic::Outputs::Lowest.register
        Alembic::Outputs::Tally.register
        Alembic::Outputs::Band.register
      end
    end
  end
end

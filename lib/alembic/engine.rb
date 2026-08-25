module Alembic
  class Engine < ::Rails::Engine
    isolate_namespace Alembic

    initializer "alembic.step_types" do |app|
      app.config.to_prepare do
        Alembic::Steps::Question.register
        Alembic::Steps::Condition.register
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

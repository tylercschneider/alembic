module Alembic
  class Transition < ApplicationRecord
    belongs_to :from_question, class_name: "Alembic::Question"
    belongs_to :to_question, class_name: "Alembic::Question"
  end
end

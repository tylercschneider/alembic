module Alembic
  module Steps
    class Question
      include Flow::Step

      label "Question"

      field :text, :text
      field :options, :records, of: { value: :string, label: :string, weight: :number }
      field :tag, :string

      names_by :text
      awaits_input
    end
  end
end

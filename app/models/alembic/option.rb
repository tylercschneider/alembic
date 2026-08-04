module Alembic
  class Option < ApplicationRecord
    include Positioned

    belongs_to :question

    validates :value, presence: true

    private

    def siblings
      question.options
    end
  end
end

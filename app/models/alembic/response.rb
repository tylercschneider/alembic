module Alembic
  class Response < ApplicationRecord
    belongs_to :diagnostic
    belongs_to :definition_version

    def self.start(diagnostic)
      create!(diagnostic: diagnostic, definition_version: diagnostic.current_definition_version)
    end
  end
end

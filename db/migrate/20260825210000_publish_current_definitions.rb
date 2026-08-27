class PublishCurrentDefinitions < ActiveRecord::Migration[8.1]
  def up
    Alembic::Flow::Definition.find_each do |diagnostic|
      current = diagnostic.current_definition_version
      next if current.nil?

      diagnostic.update_columns(published_version_id: current.id, status: "published")
    end
  end

  def down
    Alembic::Flow::Definition.update_all(published_version_id: nil)
  end
end

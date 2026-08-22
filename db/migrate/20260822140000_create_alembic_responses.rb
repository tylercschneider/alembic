class CreateAlembicResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_responses do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.references :definition_version, null: false, foreign_key: { to_table: :alembic_definition_versions }
      t.references :owner, polymorphic: true, null: true
      t.json :answers
      t.string :status
      t.string :label

      t.timestamps
    end
  end
end

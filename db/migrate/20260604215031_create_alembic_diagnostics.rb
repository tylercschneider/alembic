class CreateAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_diagnostics do |t|
      t.string :slug
      t.string :title
      t.text :summary
      t.string :kind
      t.string :status

      t.timestamps
    end
    add_index :alembic_diagnostics, :slug, unique: true
  end
end

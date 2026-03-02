class CreateProjectChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :project_changes do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.datetime :changed_at

      t.timestamps
    end
  end
end

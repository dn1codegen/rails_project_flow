class RemoveTitleFromProjectChanges < ActiveRecord::Migration[8.1]
  def change
    remove_column :project_changes, :title, :string
  end
end

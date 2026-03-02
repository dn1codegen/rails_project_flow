class CreateProjectAttachmentDescriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :project_attachment_descriptions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :attachment, null: false, foreign_key: { to_table: :active_storage_attachments }
      t.text :description, null: false, default: ""

      t.timestamps
    end

    add_index :project_attachment_descriptions, %i[project_id attachment_id], unique: true, name: "index_project_attachment_descriptions_on_project_and_attachment"
  end
end

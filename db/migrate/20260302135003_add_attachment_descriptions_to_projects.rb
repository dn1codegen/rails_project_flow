class AddAttachmentDescriptionsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :measurements_description, :text
    add_column :projects, :examples_description, :text
    add_column :projects, :installation_photos_description, :text
  end
end

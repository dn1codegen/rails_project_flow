class RemoveGeneralAttachmentDescriptionsFromProjects < ActiveRecord::Migration[8.1]
  def change
    remove_column :projects, :measurements_description, :text
    remove_column :projects, :examples_description, :text
    remove_column :projects, :installation_photos_description, :text
  end
end

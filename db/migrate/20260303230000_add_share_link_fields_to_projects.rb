class AddShareLinkFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :share_token, :string
    add_column :projects, :share_token_expires_at, :datetime
    add_index :projects, :share_token, unique: true
  end
end

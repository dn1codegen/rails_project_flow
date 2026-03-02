class AddProjectDetailsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :customer_name, :string
    add_column :projects, :address, :string
    add_column :projects, :place, :string
    add_column :projects, :product, :string
    add_column :projects, :status, :string
  end
end

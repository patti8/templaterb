class AddColumnTemplateToProject < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :template, :text
  end
end

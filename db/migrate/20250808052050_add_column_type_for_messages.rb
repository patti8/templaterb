class AddColumnTypeForMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :type, :string
  end
end

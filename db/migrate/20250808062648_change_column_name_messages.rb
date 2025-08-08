class ChangeColumnNameMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :messages, :type
    add_column :messages, :type_message, :string
  end
end

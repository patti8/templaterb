class ChangeFormatMessage < ActiveRecord::Migration[8.0]
  def change
    drop_table :messages
    create_table :messages do |t|
      t.integer :project_id
      t.text :content
      t.string :role # user or ai
      # t.string :ai_role
      t.timestamps
    end
  end
end

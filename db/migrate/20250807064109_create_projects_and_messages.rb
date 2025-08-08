class CreateProjectsAndMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.date :start_date
      t.date :end_date
      t.timestamps
    end

    create_table :messages do |t|
      t.references :project, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end
  end
end

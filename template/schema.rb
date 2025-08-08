# template.rb
# Rails Application Template for a Rails 8.0.2 app with a custom database schema

# Define a migration template for projects and messages tables
def migration_template(source, destination)
  create_file destination, <<~RUBY
    class CreateProjectsAndMessages < ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.0]
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
  RUBY
end

# Panggil metode untuk membuat file migrasi
migration_template "create_projects_and_messages.rb", "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_create_projects_and_messages.rb"
run "rails db:migrate"
# run "rails g model message"

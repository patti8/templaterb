  class AddAiIntegrationToExistingSchema < ActiveRecord::Migration[8.0]
    def change
      add_column :messages, :ai_response, :text # Store AI response
      add_column :messages, :ai_role, :string, default: 'assistant' # Role of AI
      add_index :messages, :ai_role
      # add_foreign_key :messages, :projects, column: :project_id, primary_key: :id, on_delete: :cascade
    end
  end

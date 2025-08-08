# part_3_controller.rb

# Enhance AI interactions controller
unless File.exist?('app/controllers/ai_interactions_controller.rb')
  generate :controller, 'ai_interactions', 'chat', 'chat_history'
end
inject_into_file 'app/controllers/ai_interactions_controller.rb', after: "class AiInteractionsController < ApplicationController\n" do
  <<-RUBY
    before_action :set_project

    def chat
      user = current_user
      unless user && @project
        render json: { error: 'User or project not found' }, status: :unauthorized
        return
      end
      response = AiService.chat(params[:message], @project.id, user)
      if response[:error]
        render json: { error: response[:error] }, status: :bad_request
      else
        render json: { response: response[:response], message_id: response[:message_id] }
      end
    end

    def chat_history
      @messages = Message.where(project_id: @project.id).order(created_at: :asc)
      render json: @messages.map { |m| { content: m.content, ai_response: m.ai_response, ai_role: m.ai_role, created_at: m.created_at } }
    end

    private

    def set_project
      @project = Project.find_by(name: params[:project_name] || 'Project A')
    end
  RUBY
end
puts "Updated AI interactions controller."

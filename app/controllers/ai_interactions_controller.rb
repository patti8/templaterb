class AiInteractionsController < ApplicationController
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

    def create_chat_by_project
      user = current_user
      unless user && @project
        # render json: { error: 'User or project not found' }, status: :unauthorized
        # return
        redirect_to root_path
      end


      response = AiService.chat(params[:message], @project.id, user)
      if response[:error]
        render json: { error: response[:error] }, status: :bad_request
      else
        render json: { response: response[:response], message_id: response[:message_id] }
      end
    end

    def file_templaterb
      file_template = Message.where(project_id: @project.id, type_message: "code").last
      # deugger
      content = file_template.content.gsub(/```(\w+)?\n?/, '').strip
      json = content.gsub(/```(\w+)?\n?/, '').strip
      cleaned = json.gsub(/```(\w+)?\n?/, '').strip
      json = JSON.parse(cleaned)
      code_template = json["parts"][1]["content"]

      render json: {response: code_template}
    end

    def chat_by_project
      @messages = Message.where(type_message: nil).order(created_at: :asc)
      render json: @messages #.map { |m| { content: m.content, ai_response: m.ai_response, ai_role: m.ai_role, created_at: m.created_at } }
    end


    def chat_history
      @messages = Message.where(project_id: @project.id).order(created_at: :asc)
      render json: @messages.map { |m| { content: m.content, ai_response: m.ai_response, ai_role: m.ai_role, created_at: m.created_at } }
    end

    private

    def set_project
      @project = Project.find_by(id: params[:project_id] || 'Project A')
    end

end

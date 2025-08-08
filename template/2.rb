create_file 'app/services/ai_service.rb', <<-RUBY
  class AiService
    def self.chat(message, project_id, user)
      api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
      unless api_key
        return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY in your environment.' }
      end

      response = HTTParty.post(
        'https://api.gemini.google.com/v1/chat',
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer \#{api_key}"
        },
        body: { message: message, project_id: project_id, user_id: user.id }.to_json
      )

      if response.success?
        result = JSON.parse(response.body)
        Message.create!(
          project_id: project_id,
          content: message,
          ai_response: result['response'],
          ai_role: 'user'
        )
        { response: result['response'] }
      else
        { error: "Failed to connect to Gemini AI: \#{response.message}" }
      end
    end
  end
RUBY

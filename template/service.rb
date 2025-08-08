# part_2_service.rb

# Ensure AI service exists
unless File.exist?('app/services/ai_service.rb')
  create_file 'app/services/ai_service.rb', <<-RUBY
    class AiService
      def self.chat(message, project_id, user)
        api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
        unless api_key
          return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY.' }
        end

        begin
          response = HTTParty.post(
            'https://api.gemini.google.com/v1/chat', # Adjust endpoint as per Gemini API docs
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{api_key}"
            },
            body: { message: message, project_id: project_id, user_id: user.id }.to_json
          )

          if response.success?
            result = JSON.parse(response.body)
            Message.create!(
              project_id: project_id,
              content: message,
              ai_response: result['response'],
              ai_role: 'user',
              created_at: Time.now,
              updated_at: Time.now
            )
            { response: result['response'], message_id: Message.last.id }
          else
            { error: "Failed to connect to Gemini AI: #{response.message}" }
          end
        rescue StandardError => e
          { error: "API call failed: #{e.message}" }
        end
      end
    end
  RUBY
  puts "Created AI service."
else
  puts "AI service file already exists, skipping creation."
end

  class AiService
    def self.chat(message, project_id, user)
      api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
      unless api_key
        return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY in your environment.' }
      end


      url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}"

      system_prompt_instructions = <<~PROMPT
        You are a smart AI agent that acts as a full-stack software architect and Ruby on Rails engineer.

        You will receive user requirements in natural language. Your task is to analyze the request and return a valid **JSON response** that describes the structure of a Rails Application Template.

        ### Output Format (MUST BE VALID JSON):
        Always respond using this format:

        {
          "parts": [
            {
              "type": "text",
              "content": "Explanation of what the template does and key points."
            },
            {
              "type": "code",
              "content": "```ruby\\n# template.rb\\nRAILS_VERSION = \\\"8.0.2\\\"\\n...\\n```"
            }
          ]
        }

        ### Rules:
        - Only respond with a valid JSON object. Do not include any additional explanation or commentary outside of the JSON.
        - Use `type: "code"` for Ruby templates or any code blocks.
        - Use `type: "text"` for summaries, explanations, or instructions.
        - Use `type: "docs"` only if generating documentation or multi-file content like README, LICENSE, etc.
        - Inside code blocks, use escaped newlines (\\n) if needed to maintain valid JSON.
        - You MUST include the Rails version `8.0.2` in the template.
        - The generated code should follow best practices for a Rails Application Template (.rb) and use `after_bundle` for setup steps.
        - It must work when used with: `rails new myapp -m template.rb` or `rails app:template LOCATION`.

        ### Examples of User Requests You Will Receive:
        - “I want a simple blog app with posts and comments.”
        - “A Rails app with Devise authentication and Stripe payments.”
        - “A school management app with admin dashboard and CSV import.”
        - “API-only app with JWT and PostgreSQL.”

        Now, wait for user input. When a request comes in, return a valid JSON response as defined above.
      PROMPT


      # Struktur body yang benar untuk Gemini API
      payload = {
        contents: [
          {
            role: "user",
            parts: [
              {
                text: system_prompt_instructions
              }
            ]
          },
          {
            # Respons ini membuat AI "mengadopsi" perannya dan siap menerima input.
            role: "model",
            parts: [
              {
                text: "Baik, saya mengerti. Saya adalah agen AI arsitek perangkat lunak dan engineer Ruby on Rails. Saya siap menerima permintaan Anda untuk membuat template aplikasi Rails. dan memberikan response code ruby yang lengkap tanpa penjelasan tambahan"
              }
            ]
          }
        ]
      }

      # Pesan baru dari pengguna
      user_message = message

      # Tambahkan pesan baru ke akhir array 'contents'
      payload[:contents] << {
        role: "user",
        parts: [
          {
            text: user_message
          }
        ]
      }

      response = gemini_client(url, payload)

      if response.success?
        result = JSON.parse(response.body)
        ai_response = result["candidates"][0]["content"]["parts"][0]["text"]

        template_code = ai_response
        cleaned = template_code.gsub(/```(\w+)?\n?/, '').strip
        json = JSON.parse(cleaned)

        type =  json["parts"][1]["type"]


        # from User
        save_to_message(
            project_id,
            ai_response,
            "user"
        )


        if type == "code"

          # from AI
          save_to_message(
            project_id,
            ai_response,
            "ai",
            "code"
           )

          # Struktur body yang benar untuk Gemini API
          payload[:contents] <<  {
                role: "user",
                parts: [
                  {
                    text: "buat dokumentasi untuk code ini: #{ json["parts"][1]["content"]}"
                  }
                ]
          }

          response_for_docs = gemini_client(url, payload)
          response_docs = JSON.parse(response_for_docs.body)
          ai_response_docs = response_docs["candidates"][0]["content"]["parts"][0]["text"]

          # from AI for documentations
          save_to_message(
            project_id,
            ai_response,
            "ai",
            "docs"
           )
        else
           # from AI
           save_to_message(
            project_id,
            ai_response,
            "ai",
            nil
           )
        end


        { response: json["parts"][0]["content"] }
      else
        { error: "Failed to connect to Gemini AI: #{response.message}" }
      end
    end


    def self.gemini_client(url, payload)
      HTTParty.post(
        url,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: payload.to_json
      )
    end

    def self.save_to_message(project_id, message, role, type_message=nil)
        # Create a new message record
        Message.create(
          project_id: project_id,
          content: message,
          role: role,
          type_message: type_message # Assuming 'type' is the enum defined in the Message model
        )
    end


  end

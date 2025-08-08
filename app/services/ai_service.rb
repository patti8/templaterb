  class AiService
    def self.chat(message, project_id, user)
      api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
      unless api_key
        return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY in your environment.' }
      end


      url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}"

      system_prompt_instructions = <<~PROMPT
        You are an expert AI acting as a full-stack software architect and Ruby on Rails engineer. Your task is to analyze user requirements provided in natural language and generate a valid **JSON response** describing a Ruby on Rails Application Template.

        ### Output Format
        Respond with a valid JSON object in the following structure:

        ```json
        {
          "parts": [
            {
              "type": "text",
              "content": "A clear explanation of the template's purpose, key features, and any assumptions made if the request was unclear."
            },
            {
              "type": "code",
              "content": "```ruby\\n# template.rb\\nRAILS_VERSION = \\\"8.0.2\\\"\\n# Rails template code here\\n```"
            }
          ]
        }
        ```

        ### Rules
        - Respond **only** with a valid JSON object. Do not include any text or commentary outside the JSON.
        - Use `type: "text"` for explanations, summaries, or to document assumptions made due to unclear requirements.
        - Use `type: "code"` for the Ruby on Rails template code.
        - Use `type: "docs"` only for generating documentation files (e.g., README.md, LICENSE).
        - Ensure code blocks in `content` use escaped newlines (`\\n`) to maintain valid JSON.
        - The template must specify Rails version `8.0.2` using `RAILS_VERSION = "8.0.2"`.
        - Generated code must follow Ruby on Rails best practices, be compatible with `rails new myapp -m template.rb` or `rails app:template LOCATION`, and use `after_bundle` for setup steps.
        - Ensure the template is functional, modular, and handles dependencies appropriately.

        ### Handling Unclear Requests
        - If the user's request is vague or lacks detail (e.g., "Create a Rails app"), assume a minimal, standard Rails application with a basic MVC structure and default gems (e.g., SQLite, Puma).
        - In the `text` part, explicitly state any assumptions made to clarify the implementation (e.g., "Assuming a basic Rails app with a single model and CRUD functionality").
        - If clarification is needed beyond reasonable assumptions, include in the `text` part a note suggesting what additional details would improve the response (e.g., "Please specify authentication needs or database preferences").

        ### Example User Requests
        - "Create a blog app with posts and comments."
        - "Build a Rails app with Devise authentication and Stripe integration."
        - "Develop a school management app with an admin dashboard and CSV import."
        - "Generate an API-only Rails app with JWT authentication and PostgreSQL."
        - "Create a Rails app" (vague request).

        Analyze the user input, make reasonable assumptions if needed, and return a JSON response adhering to the format and rules above.
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

        type =  json["parts"][1]["type"] if json.present?

        # from User
        save_to_message(
            project_id,
            message,
            "user"
        )


        if type == "code" # || type == "docs"

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
          save_to_message(
              project_id,
              ai_response,
              "ai"
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

  class AiService
    def self.chat(message, project_id, user)
      api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
      unless api_key
        return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY in your environment.' }
      end


      url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{api_key}"

      system_prompt_instructions = <<-PROMPT
      You are a smart AI agent that acts as a full-stack software architect and Ruby on Rails engineer.

      You will receive user requirements or requests in natural language. Your task is to understand the intent and generate a working **Rails Application Template** (`.rb` file) that can be used with `rails new myapp -m template.rb`.

      The generated template should:
      - rails version for 8.0.2
      - Include all required Rails gems and configurations
      - Include commands such as `gem`, `after_bundle`, `generate`, etc.
      - Be modular and flexible for future extensions
      - Work for both simple and complex use cases (e.g., blog app, e-commerce with Stripe integration, admin dashboard with authentication)
      - Avoid including static content (like README or views) unless asked

      ### Instructions:
      1. Analyze the user's natural language request.
      2. Determine the type of app and required gems.
      3. Generate a valid `.rb` Rails application template that implements those needs.
      4. Include comments in the template to clarify what's being done in each section.
      5. Use best practices for gem usage and template structure.

      ### Additional Rules:
      - Always use `after_bundle` to run setup tasks (e.g., `generate`, `rails db:create`, `git init`, etc.)
      - Use popular libraries for authentication (like Devise), payments (like Stripe), admin dashboards (like Administrate), etc.
      - The template must be executable via `rails new myapp -m template.rb` without error or `rails app:template ./template.rb`

      ---

      #### 🧠 EXAMPLE REQUESTS THE USER MIGHT ASK:

      - “I want a simple blog app with posts and comments.”
      - “I need a Rails app with authentication and Stripe payments.”
      - “Buat aplikasi manajemen sekolah dengan admin dashboard dan import CSV untuk siswa.”
      - “I need an app with API-only mode, JWT auth, and PostgreSQL.”

      ---

      Now, wait for user input and generate the Rails Application Template `.rb` file based on it.
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

      response = HTTParty.post(
        url,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: payload.to_json
      )



      if response.success?
        result = JSON.parse(response.body)
        ai_response = result["candidates"][0]["content"]["parts"][0]["text"]

        # from User
        Message.create!(
          project_id: project_id,
          content: message,
          role: "user"
        )

        # from AI
        Message.create!(
          project_id: project_id,
          content: ai_response,
          role: "ai"
        )
        template_code = ai_response
        debugger
        { response: ai_response }
      else
        { error: "Failed to connect to Gemini AI: #{response.message}" }
      end
    end

    # def self.valid_template?(template_code)
    #   # 1. Ekstrak kode di antara tanda pagar Markdown
    #   #    Regex ini mencari konten di antara ```ruby dan ```
    #   cleaned_code = template_code.match(/```ruby\n(.*)\n```/m)

    #   # 2. Pastikan ada yang cocok, lalu validasi
    #   if cleaned_code && cleaned_code[1]
    #     template_code = cleaned_code[1]
    #     puts "Kode yang sudah dibersihkan:\n---\n#{template_code}\n---"

    #     # Sekarang validasi kode yang sudah bersih
    #     puts "Hasil validasi: #{valid_template?(template_code)}" # Seharusnya sekarang true
    #   else
    #     puts "Tidak dapat menemukan kode Ruby di dalam string."
    #   end

    #   # 1. Pemeriksaan Sintaks
    #   # Ripper.sexp akan mengembalikan nil jika ada syntax error.
    #   return false if Ripper.sexp(cleaned_code).nil?

    #   # 2. Pemeriksaan Kata Kunci Esensial (Opsional tapi direkomendasikan)
    #   # Memastikan template berisi perintah-perintah umum.
    #   required_keywords = ['gem', 'generate', 'rails_command', 'after_bundle']

    #   # Memeriksa apakah setidaknya salah satu kata kunci ada.
    #   # Anda bisa mengubah ini menjadi .all? jika semua kata kunci wajib ada.
    #   return required_keywords.any? { |keyword| template_code.include?(keyword) }

    # rescue
    #   # Menangani error tak terduga selama validasi
    #   return false
    # end

    def self.valid_template_v2?(template_code)
      # Pastikan text selalu terisi
      text = template_code.include?("\\n") ? template_code.gsub("\\n", "\n") : template_code

      # Cocokkan dengan blok kode Ruby tanpa teks tambahan
      ruby_block = /\A```ruby\s*\n(.+?)\n```$/m
      match = text.match(ruby_block)
      return false unless match

      content = match[1]

      # Keyword penting sebagai validasi isi (bisa disesuaikan)
      required_keywords = [
        "RAILS_VERSION", "gem", "after_bundle do", "generate", "rails_command", "route", "git"
      ]

      required_keywords.all? { |kw| content.include?(kw) }
    end




  end

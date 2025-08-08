# add_ai_ui_integration.rb

# Add required gems to Gemfile
gemfile = File.read('Gemfile')
unless gemfile.include?('httparty')
  append_file 'Gemfile', <<-RUBY
    gem 'httparty' # HTTP client for REST API requests to Gemini AI
  RUBY
  puts "Added HTTParty gem to Gemfile. Please run 'bundle install'."
end

# Create migration for AI integration if not exists
migration_name = "AddAiIntegrationToExistingSchema"
unless Dir.glob("db/migrate/*#{migration_name.downcase.gsub(' ', '_')}*.rb").any?
  migration_content = <<-RUBY
    class #{migration_name} < ActiveRecord::Migration[8.0]
      def change
        add_column :messages, :ai_response, :text # Store AI response
        add_column :messages, :ai_role, :string, default: 'assistant' # Role of AI
        add_index :messages, :ai_role
        add_foreign_key :messages, :projects, column: :project_id, primary_key: :id, on_delete: :cascade
      end
    end
  RUBY
  timestamp = Time.now.strftime("%Y%m%d%H%M%S")
  create_file "db/migrate/#{timestamp}_#{migration_name.downcase.gsub(' ', '_')}.rb", migration_content
  puts "Created migration for AI integration. Please run 'rails db:migrate'."
end

# Create controller for AI interactions
unless File.exist?('app/controllers/ai_interactions_controller.rb')
  generate :controller, 'ai_interactions', 'chat', 'chat_history'
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
  puts "Created AI interactions controller."
end

# Create AI service
unless File.exist?('app/services/ai_service.rb')
  create_file 'app/services/ai_service.rb', <<-RUBY
    class AiService
      def self.chat(message, project_id, user)
        api_key = Rails.application.config.x.gemini_api_key || ENV['GEMINI_API_KEY']
        unless api_key
          return { error: 'Gemini API key not configured. Please set GEMINI_API_KEY in your environment.' }
        end

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
          message_record = Message.create!(
            project_id: project_id,
            content: message,
            ai_response: result['response'],
            ai_role: 'user',
            created_at: Time.now,
            updated_at: Time.now
          )
          { response: result['response'], message_id: message_record.id }
        else
          { error: "Failed to connect to Gemini AI: #{response.message}" }
        end
      end
    end
  RUBY
  puts "Created AI service."
end

# Update routes
route_content = File.read('config/routes.rb')
unless route_content.include?('ai_interactions')
  inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
    <<-RUBY
      get 'ai_interactions/chat', to: 'ai_interactions#chat', as: :ai_chat
      get 'ai_interactions/chat_history', to: 'ai_interactions#chat_history', as: :ai_chat_history
    RUBY
  end
  puts "Added AI interaction routes to routes.rb."
end

# Create layout and view files
unless File.exist?('app/views/layouts/application.html.erb')
  create_file 'app/views/layouts/application.html.erb', <<-ERB
    <!DOCTYPE html>
    <html>
    <head>
      <title>RailsGenAI</title>
      <%= csrf_meta_tags %>
      <%= csp_meta_tags %>
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
      <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
      <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
      <style>
        .rails-icon { color: #d32f2f; }
        .btn-primary { background-color: #d32f2f; color: white; border: none; border-radius: 4px; }
        .btn-secondary { background-color: #e0e0e0; color: #333; border: none; border-radius: 4px; }
        .panel { background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .tab-btn.active { background-color: #d32f2f; color: white; }
        .tab-content { display: block; }
        .tab-content.hidden { display: none; }
        .mock-browser { border: 1px solid #ccc; border-radius: 4px; }
        .mock-browser-header { background-color: #f5f5f5; padding: 4px; display: flex; align-items: center; }
        .mock-browser-dots span { display: inline-block; width: 12px; height: 12px; border-radius: 50%; }
        .mock-browser-url { flex-grow: 1; text-align: center; font-size: 12px; color: #666; }
        .mock-browser-body { padding: 10px; min-height: 200px; }
        .chat-message { margin: 5px 0; }
        .loader { border: 4px solid #f3f3f3; border-top: 4px solid #d32f2f; border-radius: 50%; width: 16px; height: 16px; animation: spin 1s linear infinite; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
    </head>
    <body>
      <%= yield %>
    </body>
    </html>
  ERB
  puts "Created application layout."
end

unless File.exist?('app/views/ai_interactions/index.html.erb')
  create_file 'app/views/ai_interactions/index.html.erb', <<-ERB
    <!-- Sidebar -->
    <aside class="w-64 bg-white flex flex-col p-4 border-r border-slate-200 flex-shrink-0">
      <div class="flex items-center gap-3 mb-8">
        <i class="fas fa-gem text-3xl rails-icon"></i>
        <h1 class="text-xl font-bold text-slate-800">RailsGen AI</h1>
      </div>
      <h2 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Projects</h2>
      <nav class="flex-grow">
        <ul>
          <li><%= link_to 'Project A', ai_chat_path(project_name: 'Project A'), class: "flex items-center gap-3 px-3 py-2 bg-slate-100 rounded-lg text-slate-800 font-medium" do %>
            <i class="fas fa-folder-open rails-icon"></i> <span>Project A</span>
          <% end %></li>
          <li class="mt-1"><%= link_to 'E-commerce App', '#', class: "flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-slate-100 text-slate-600" do %>
            <i class="fas fa-folder text-slate-400"></i> <span>E-commerce App</span>
          <% end %></li>
        </ul>
      </nav>
      <div class="mt-auto">
        <%= button_to "Simpan Proyek", '#', class: "w-full btn-secondary flex items-center justify-center gap-2 bg-slate-200 hover:bg-slate-300" do %>
          <i class="fas fa-save"></i>
          <span>Simpan Proyek</span>
        <% end %>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-6 p-6" x-data="chat()">
      <!-- Left Panel: Chat History -->
      <div class="panel flex flex-col h-full max-h-screen">
        <div class="p-4 border-b border-slate-200">
          <h2 class="text-lg font-semibold flex items-center gap-2"><i class="fas fa-comments rails-icon"></i> Riwayat Chat (Project A)</h2>
        </div>
        <div id="chat-history" class="flex-grow p-4 overflow-y-auto flex flex-col" x-ref="history">
          <template x-for="message in chatHistory" :key="message.id">
            <div class="chat-message" :class="message.role === 'user' ? 'text-right' : 'text-left' mb-2">
              <p class="inline-block p-2 rounded-lg" :class="message.role === 'user' ? 'bg-[var(--rails-red)] text-white' : 'bg-slate-100 text-slate-800'" x-text="message.content"></p>
            </div>
          </template>
        </div>
        <div class="p-4 border-t border-slate-200">
          <div class="relative">
            <input type="text" id="ai-prompt" class="w-full bg-slate-100 border border-slate-300 rounded-lg pl-4 pr-12 py-3 text-slate-800 focus:outline-none focus:ring-2 focus:ring-[var(--rails-red)]" placeholder="Ketik permintaan Anda..." x-model="prompt" @keyup.enter="sendMessage">
            <button id="generate-btn" class="absolute right-2 top-1/2 -translate-y-1/2 btn-primary !p-2 h-9 w-9 flex items-center justify-center" @click="sendMessage">
              <i class="fas fa-paper-plane"></i>
            </button>
          </div>
          <div id="loading-indicator" class="hidden mt-2 flex items-center gap-3 text-slate-500" x-show="loading">
            <div class="loader"></div>
            <span>AI sedang bekerja...</span>
          </div>
          <div id="error-message" class="hidden mt-2 text-red-700 bg-red-100 p-3 rounded-lg border border-red-200" x-show="error" x-text="error"></div>
        </div>
      </div>

      <!-- Right Panel: Tabbed Workspace -->
      <div class="flex-grow flex flex-col panel h-full max-h-screen">
        <div class="p-2 border-b border-slate-200 flex gap-2">
          <button data-tab="editor" class="tab-btn px-4 py-2 flex items-center gap-2" :class="{ 'active': activeTab === 'editor' }" @click="activeTab = 'editor'"><i class="fab fa-dev"></i> Editor</button>
          <button data-tab="preview" class="tab-btn px-4 py-2 flex items-center gap-2" :class="{ 'active': activeTab === 'preview' }" @click="activeTab = 'preview'"><i class="fas fa-eye"></i> Live Preview</button>
          <button data-tab="explanation" class="tab-btn px-4 py-2 flex items-center gap-2" :class="{ 'active': activeTab === 'explanation' }" @click="activeTab = 'explanation'"><i class="fas fa-book-open"></i> Penjelasan</button>
        </div>
        <div class="p-6 flex-grow overflow-y-auto">
          <div id="editor-panel" class="tab-content" :class="{ 'hidden': activeTab !== 'editor' }">
            <pre id="code-editor" class="code-editor h-full" x-text="chatHistory.length > 0 ? chatHistory[chatHistory.length - 1].content : ''"></pre>
          </div>
          <div id="preview-panel" class="tab-content" :class="{ 'hidden': activeTab !== 'preview' }">
            <div class="mock-browser h-full">
              <div class="mock-browser-header">
                <div class="mock-browser-dots flex gap-1.5">
                  <span style="background-color: #f87171;"></span><span style="background-color: #fbbd23;"></span><span style="background-color: #34d399;"></span>
                </div>
                <div class="mock-browser-url">http://localhost:3000</div>
              </div>
              <div id="live-preview-body" class="mock-browser-body" x-html="chatHistory.length > 0 ? `<p>${chatHistory[chatHistory.length - 1].content}</p>` : ''"></div>
            </div>
          </div>
          <div id="explanation-panel" class="tab-content" :class="{ 'hidden': activeTab !== 'explanation' }">
            <div id="explanation-content" class="prose prose-slate max-w-none text-slate-700" x-html="chatHistory.length > 0 ? `AI response explanation: ${chatHistory[chatHistory.length - 1].content}` : ''"></div>
          </div>
        </div>
      </div>
    </main>

    <script>
      function loadChatHistory() {
        fetch('/ai_interactions/chat_history', {
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          credentials: 'same-origin',
          body: JSON.stringify({ project_name: 'Project A' })
        })
        .then(response => response.json())
        .then(data => {
          document.querySelector('[x-ref="history"]').dispatchEvent(new CustomEvent('load-history', { detail: data }));
        });
      }

      document.addEventListener('alpine:init', () => {
        Alpine.data('chat', () => ({
          prompt: '',
          chatHistory: [],
          activeTab: 'editor',
          loading: false,
          error: '',

          init() {
            loadChatHistory();
            this.$watch('chatHistory', () => {
              this.$nextTick(() => {
                const history = this.$refs.history;
                history.scrollTop = history.scrollHeight;
              });
            });
            this.$refs.history.addEventListener('load-history', (e) => {
              this.chatHistory = e.detail.map(msg => ({ id: Math.random(), content: msg.content, role: msg.ai_role }));
            });
          },

          sendMessage() {
            if (!this.prompt.trim()) return;

            this.loading = true;
            this.error = '';

            fetch('/ai_interactions/chat', {
              method: 'GET',
              headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
              },
              credentials: 'same-origin',
              body: JSON.stringify({ message: this.prompt, project_name: 'Project A' })
            })
            .then(response => response.json())
            .then(data => {
              this.loading = false;
              if (data.error) {
                this.error = data.error;
              } else {
                this.chatHistory.push({ id: Date.now(), content: this.prompt, role: 'user' });
                this.chatHistory.push({ id: Date.now() + 1, content: data.response, role: 'assistant' });
                this.prompt = '';
              }
            })
            .catch(error => {
              this.loading = false;
              this.error = 'Error: ' + error.message;
            });
          }
        }));
      });
    </script>
  ERB
  puts "Created AI interactions view."
end

# Update application.js (optional, since Alpine is in layout)
application_js = File.read('app/javascript/packs/application.js') rescue ''
unless application_js.include?('alpine')
  create_file 'app/javascript/packs/application.js', <<-JS unless File.exist?('app/javascript/packs/application.js')
    // Placeholder for other JS if needed
  JS
  append_file 'app/javascript/packs/application.js', "\n// Alpine.js is included in the layout\n"
  puts "Ensured application.js exists and noted Alpine.js inclusion."
end

# Update environment configuration
environment_content = File.read('config/application.rb')
unless environment_content.include?("config.x.gemini_api_key")
  inject_into_file 'config/application.rb', after: "class Application < Rails::Application\n" do
    <<-RUBY
      config.x.gemini_api_key = ENV['GEMINI_API_KEY']
    RUBY
  end
  puts "Added Gemini API key configuration to application.rb."
end

puts "UI/UX and AI integration setup complete. Please run 'bundle install', 'rails db:migrate', and ensure GEMINI_API_KEY is set. Then restart your server."

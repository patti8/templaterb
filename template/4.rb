# template.rb

# Set Rails version (for reference, though this is for an existing project)
rails_version = "8.0.2"
puts "Enhancing existing Rails application with version compatibility for #{rails_version}..."

# Add required gems
gem 'httparty' # HTTP client for REST API requests to Gemini AI

after_bundle do
  # Ensure HTTParty is available
  run 'bundle install' if `gem list | grep httparty`.empty?

  # Create AI service
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
              { response: result['response'] }
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
  end

  # Enhance AI interactions controller
  unless File.exist?('app/controllers/ai_interactions_controller.rb')
    create_file 'app/controllers/ai_interactions_controller.rb', <<-RUBY
      class AiInteractionsController < ApplicationController
        before_action :set_project

        def chat
          user = current_user
          unless user && @project
            render json: { error: 'User or project not found' }, status: :unauthorized
            return
          end
          response = AiService.chat(params[:message], @project.id, user)
          render json: response
        end

        def chat_history
          @messages = Message.where(project_id: @project.id).order(created_at: :asc)
          render json: @messages.map { |m| { content: m.content, ai_response: m.ai_response, ai_role: m.ai_role, created_at: m.created_at } }
        end

        private

        def set_project
          @project = Project.find_by(name: params[:project_name] || 'Project A')
        end
      end
    RUBY
    puts "Created or updated AI interactions controller."
  end

  # Create view files
  unless File.exist?('app/views/ai_interactions/index.html.erb')
    create_file 'app/views/ai_interactions/index.html.erb', <<-ERB
      <main class="h-screen flex bg-slate-100">
        <%= render "sidebar" %>

        <!-- Main Content -->
        <main class="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-6 p-6">
          <!-- Left Panel: Chat History -->
          <div class="panel flex flex-col h-full max-h-screen">
            <div class="p-4 border-b border-slate-200">
              <h2 class="text-lg font-semibold flex items-center gap-2"><i class="fas fa-comments rails-icon"></i> Riwayat Chat (Project A)</h2>
            </div>
            <div id="chat-history" class="flex-grow p-4 overflow-y-auto flex flex-col" x-data="chat()" x-init="loadChatHistory()">
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

        <%= render "js" %>
      </main>
    ERB
    puts "Created AI interactions view."
  end

  # Create JavaScript partial
  unless File.exist?('app/views/ai_interactions/_js.html.erb')
    create_file 'app/views/ai_interactions/_js.html.erb', <<-ERB
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
            document.getElementById('chat-history').dispatchEvent(new CustomEvent('load-history', { detail: data }));
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
                  const history = document.getElementById('chat-history');
                  history.scrollTop = history.scrollHeight;
                });
              });
              document.getElementById('chat-history').addEventListener('load-history', (

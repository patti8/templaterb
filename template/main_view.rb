# part_6_main_view.rb

# Create main view
unless File.exist?('app/views/ai_interactions/index.html.erb')
  create_file 'app/views/ai_interactions/index.html.erb', <<-ERB
    <main class="h-screen flex bg-slate-100">
      <%= render "shared/sidebar" %>

      <!-- Main Content -->
      <main class="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-6 p-6" x-data="chat()" x-init="init()">
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
    </main>
  ERB
  puts "Created AI interactions view."
else
  puts "AI interactions view already exists, skipping creation."
end

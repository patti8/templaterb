# part_5_layout_partial.rb

# Create or update layout
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
      <%= render "shared/sidebar" %>
      <%= yield %>
    </body>
    </html>
  ERB
  puts "Created application layout."
end

# Create sidebar partial
unless File.exist?('app/views/shared/_sidebar.html.erb')
  create_file 'app/views/shared/_sidebar.html.erb', <<-ERB
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
  ERB
  puts "Created sidebar partial."
else
  puts "Sidebar partial already exists, skipping creation."
end

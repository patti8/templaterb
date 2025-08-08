# part_4_routes.rb

# Update routes if not already present
route_content = File.read('config/routes.rb')
unless route_content.include?('ai_interactions/chat') && route_content.include?('ai_interactions/chat_history')
  inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
    <<-RUBY
      get 'ai_interactions/chat', to: 'ai_interactions#chat', as: :ai_chat
      get 'ai_interactions/chat_history', to: 'ai_interactions#chat_history', as: :ai_chat_history
    RUBY
  end
  puts "Updated routes.rb with AI interaction routes."
else
  puts "AI interaction routes already present in routes.rb."
end

# part_1_gems.rb

# Set Rails version (for compatibility check)
rails_version = "8.0.2"
puts "Enhancing existing Rails application with version compatibility #{rails_version}..."

# Add required gems
gemfile = File.read('Gemfile')
unless gemfile.include?('httparty')
  append_file 'Gemfile', <<-RUBY
    gem 'httparty' # HTTP client for REST API requests to Gemini AI
  RUBY
  puts "Added HTTParty gem to Gemfile. Please run 'bundle install' if not already done."
else
  puts "HTTParty gem already present in Gemfile."
end

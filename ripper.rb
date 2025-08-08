require 'ripper'

def valid_template?(template_code)
  # 1. Pemeriksaan Sintaks
  # Ripper.sexp akan mengembalikan nil jika ada syntax error.
  return false if Ripper.sexp(template_code).nil?

  # 2. Pemeriksaan Kata Kunci Esensial (Opsional tapi direkomendasikan)
  # Memastikan template berisi perintah-perintah umum.
  required_keywords = ['gem', 'generate', 'rails_command', 'after_bundle']

  # Memeriksa apakah setidaknya salah satu kata kunci ada.
  # Anda bisa mengubah ini menjadi .all? jika semua kata kunci wajib ada.
  return required_keywords.any? { |keyword| template_code.include?(keyword) }

rescue
  # Menangani error tak terduga selama validasi
  return false
end

# --- Contoh Penggunaan ---

# Template yang valid dari permintaan Anda
valid_template = <<-RUBY
# template.rb for a simple Todo application
gem 'puma'
def generate_app
  generate(:model, "Task title:string completed:boolean")
end
def after_bundle
  rails_command "db:create"
  generate_app
end
after_bundle
RUBY

# Template yang tidak valid (syntax error)
invalid_template = <<-RUBY
gem 'puma'
def my_func
  puts "hello"
# 'end' tidak ada, ini akan menyebabkan error
RUBY

# Template yang sintaksnya benar tapi tidak seperti template Rails
not_a_template = <<-RUBY
puts "Hello, world!"
puts 2 + 2
RUBY

puts "Template 1 (Valid): #{valid_template?(valid_template)}"         # Output: true
puts "Template 2 (Invalid Syntax): #{valid_template?(invalid_template)}" # Output: false
puts "Template 3 (Bukan Template): #{valid_template?(not_a_template)}"  # Output: false

source "https://rubygems.org"

ruby "~> 3.4"

gem "rails", "~> 8.1"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tailwindcss-rails", "~> 4.6"   # v4 = @theme tokens; do not float to v5 unpinned
gem "devise", "~> 5.0"
gem "bootsnap", require: false
gem "rubyzip", require: "zip"   # unzip/rezip the .docx quote templates

group :development do
  gem "web-console"
  gem "letter_opener"   # preview outgoing mail in the browser instead of real SMTP
end

group :development, :test do
  gem "debug", require: "debug/prelude"
  gem "dotenv-rails"       # secrets live in .env (gitignored), never in code — see CLAUDE.md Part 4
  gem "rspec-rails"        # must be here, not :test only — generators run in development
  gem "factory_bot_rails"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "database_cleaner-active_record"
end

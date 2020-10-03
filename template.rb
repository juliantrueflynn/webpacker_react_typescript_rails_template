# frozen_string_literal: true

# Cleanup Gemfile
gsub_file "Gemfile", "gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]\n", ""
gsub_file "Gemfile", "# Windows does not include zoneinfo files, so bundle the tzinfo-data gem\n", ""

# Gems group: development, test
inject_into_file "Gemfile", after: "group :development, :test do" do
  <<-RUBY

  gem "factory_bot_rails"
  gem "rspec-rails"
  RUBY
end

# Gems group: development
inject_into_file "Gemfile", after: "group :development do" do
  <<-RUBY

  gem "rubocop", "~> 0.83.0", require: false
  gem "rubocop-rails", require: false
  RUBY
end

# Gems group: test
if File.read("Gemfile").match?(/group :test do/)
  append_to_file "Gemfile", after: "group :test do" do
    <<-RUBY

    gem "faker"
    gem "shoulda-matchers"
    gem "simplecov", require: false
    gem "webmock", require: false
    RUBY
  end
else
  gem_group :test do
    gem "faker"
    gem "shoulda-matchers"
    gem "simplecov", require: false
    gem "webmock", require: false
  end
end

after_bundle do
  # rubocop:disable Layout/LineLength
  run "curl -L https://raw.githubusercontent.com/juliantrueflynn/webpacker_react_typescript_rails_template/main/.rubocop.yml > .rubocop.yml"
  # rubocop:enable Layout/LineLength
  run "rubocop -a"
end

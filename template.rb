# frozen_string_literal: true

inject_into_file "Gemfile", after: "group :development do" do
  <<-RUBY

  gem "rubocop", "~> 0.83.0", require: false
  gem "rubocop-rails", require: false
  RUBY
end

# rubocop:disable Layout/LineLength
run "curl -L https://raw.githubusercontent.com/juliantrueflynn/webpacker_react_typescript_rails_template/main/.rubocop.yml > .rubocop.yml"
# rubocop:enable Layout/LineLength

after_bundle do
  run "rubocop -a"
end

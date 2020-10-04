# frozen_string_literal: true

source_paths.unshift(File.dirname(__FILE__))

# Cleanup Gemfile
gsub_file "Gemfile", "gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]\n", ""
gsub_file "Gemfile", "# Windows does not include zoneinfo files, so bundle the tzinfo-data gem\n", ""
# Ensure that we're using latest version of webpacker
gsub_file "Gemfile", "gem 'webpacker', '~> 4.0'", 'gem "webpacker", ">= 5.2"'

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
  inject_into_file "Gemfile", after: "group :test do" do
    <<-RUBY

  gem "faker"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock", require: false
    RUBY
  end
else
  gem_group :test do
    gem "capybara"
    gem "faker"
    gem "shoulda-matchers"
    gem "simplecov", require: false
    gem "webmock", require: false
  end
end

run "yarn add -s @types/node core-js regenerator-runtime"
run <<~YARN.squish
  yarn add -D -s
  @pmmmwh/react-refresh-webpack-plugin
  @testing-library/jest-dom
  @testing-library/react
  @testing-library/user-event
  @types/jest
  @typescript-eslint/eslint-plugin
  babel-eslint
  babel-jest
  eslint-config-prettier
  eslint-plugin-import
  eslint-plugin-jest-dom
  eslint-plugin-jsx-a11y
  eslint-plugin-prettier
  eslint-plugin-react
  eslint-plugin-react-hooks
  eslint-plugin-testing-library
  fork-ts-checker-webpack-plugin
  husky
  jest-watch-typeahead
  lint-staged
  prettier
  react-refresh
YARN

copy_file "files/.eslintignore", ".eslintignore"
copy_file "files/.eslintrc.json", ".eslintrc.json"
copy_file "files/.rubocop.yml", ".rubocop.yml"

def run_webpacker_generators
  rails_command "webpacker:install:react"
  rails_command "webpacker:install:typescript"
end

def apply_babel_config_changes
  # Setup fast refresh config.
  inject_into_file "babel.config.js", after: "plugins: [" do
    "\n      (process.env.WEBPACK_DEV_SERVER) && 'react-refresh/babel',"
  end

  # Remove babel-plugin-transform-react-prop-types from babel config.
  gsub_file(
    "babel.config.js",
    /,\s+isProductionEnv && \[.*'babel-plugin-transform-react-remove-prop-types'.*\]/ms,
    "\n    ]"
  )
end

def setup_rspec
  generate "rspec:install"

  inject_into_file "spec/rails_helper.rb", before: "# This file is copied to spec/" do
    <<~RUBY
      require "simplecov"
      SimpleCov.start "rails"

    RUBY
  end
  inject_into_file "spec/rails_helper.rb", after: "Rails is not loaded until this point!" do
    "\n" + 'require "faker"'
  end

  directory "files/spec/support", "spec/support"
  comment_lines "spec/rails_helper.rb", /config\.fixture_path =/
  uncomment_lines "spec/rails_helper.rb", /Dir\[Rails\.root\.join/
  # RSpec uses comment blocks to comment out config in spec_helper.
  gsub_file "spec/spec_helper.rb", "=begin", ""
  gsub_file "spec/spec_helper.rb", "=end", ""
end

after_bundle do
  run_webpacker_generators
  setup_rspec

  copy_file "files/config/webpack/development.js", "config/webpack/development.js", force: true

  run "rubocop -a &>/dev/null"

  run "yarn remove -s prop-types babel-plugin-transform-react-remove-prop-types"

  remove_file "app/javascript/packs/hello_react.jsx"
  remove_file "app/javascript/packs/hello_typescript.ts"
  run "mv app/javascript/packs/application.js app/javascript/packs/application.ts"

  apply_babel_config_changes
end

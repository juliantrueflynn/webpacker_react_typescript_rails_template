# frozen_string_literal: true

def source_directory
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(File.dirname(__FILE__))
  else
    source_paths.unshift("#{File.dirname(__FILE__)}/tree/fix-remote-paths/files")
  end
end

def say_info(message)
  say "-------------------------------------------------------------------------", :blue
  say message, :blue
  say "-------------------------------------------------------------------------", :blue
end

# Cleanup Gemfile
say_info "Cleanup Gemfile and ensure latest version of webpacker"
gsub_file "Gemfile", "gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]\n", ""
gsub_file "Gemfile", "# Windows does not include zoneinfo files, so bundle the tzinfo-data gem\n", ""
gsub_file "Gemfile", "gem 'webpacker', '~> 4.0'", 'gem "webpacker", ">= 5.2"'

say_info "Install gems"
# Gems group: all
inject_into_file "Gemfile", before: "group :development, :test do" do
  'gem "dotenv-rails", require: "dotenv/rails-now"' + "\n"
end

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

# Environment custom configurations
inject_into_file "config/application.rb", after: /config.load_defaults .*?$/ do
  <<-RUBY


    config.x.capybara_max_wait_time = ENV.fetch("CAPYBARA_MAX_WAIT_TIME", 5)
    config.x.selenium_host = ENV.fetch("SELENIUM_HOST", "selenium")
    config.x.selenium_port = ENV.fetch("SELENIUM_PORT", "4444")
    config.x.selenium_server_host = ENV.fetch("SELENIUM_SERVER_HOST", "web")
  RUBY
end

def run_webpacker_generators
  rails_command "webpacker:install:react"

  # Remove unused prop types libraries, which are unneeded with typescript.
  gsub_file "package.json", /"prop-types": ".*?".*?$/, ""
  gsub_file "package.json", /"babel-plugin-transform-react-remove-prop-types": ".*?".*?$/, ""

  rails_command "webpacker:install:typescript"
  gsub_file "config/webpacker.yml", "hmr: false", "hmr: true"
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

  comment_lines "spec/rails_helper.rb", /config\.fixture_path =/
  uncomment_lines "spec/rails_helper.rb", /Dir\[Rails\.root\.join/
  # RSpec uses comment blocks to comment out config in spec_helper.
  gsub_file "spec/spec_helper.rb", "=begin", ""
  gsub_file "spec/spec_helper.rb", "=end", ""
  run "spring stop"
end

def apply_changes_to_gitignore
  append_to_file ".gitignore", <<~GIT

  # Ignore RSpec generated file
  spec/examples.txt

  .env
  .env.*
  !.env.development

  .DS_Store
  GIT
end

def apply_extra_yarn_dependencies_and_scripts
  run "yarn add -s @types/node core-js regenerator-runtime"
  run <<~YARN.squish
    yarn add -D -s
    @pmmmwh/react-refresh-webpack-plugin
    @testing-library/jest-dom
    @testing-library/react
    @testing-library/user-event
    @types/jest
    @typescript-eslint/eslint-plugin
    @typescript-eslint/parser
    babel-eslint
    babel-jest
    eslint
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

  inject_into_file "package.json", after: /"private": true,\s+/ do
    <<~JSON
      "scripts": {
        "test": "jest --verbose --watchAll",
        "test:coverage": "jest --verbose --coverage",
        "lint": "eslint 'app/javascript/**/*.{ts,tsx,js}'",
        "lint:fix": "eslint 'app/javascript/**/*.{ts,tsx,js}' --fix"
      },
    JSON
  end

  inject_into_file "package.json", before: /}\s+}\s+/ do
    <<~JSON
      },
      "husky": {
        "hooks": {
          "pre-commit": "lint-staged"
        }
      },
      "lint-staged": {
        "src/**/*.{js,jsx,ts,tsx,json,css,scss,md}": [
          "eslint 'app/javascript/**/*.{ts,tsx,js}' --fix"
        ]
    JSON
  end

  # Cleaning up package.json formatting issues from previous injections.
  run "node_modules/.bin/eslint 'package.json' --fix"
end

after_bundle do
  say_info "Setting up webpacker"
  run_webpacker_generators

  say_info "Copying files"
  directory source_directory, "./", force: true

  say_info "Adding yarn dependencies"
  apply_extra_yarn_dependencies_and_scripts

  say_info "Setting up rspec"
  setup_rspec

  apply_changes_to_gitignore

  say_info "Cleaning generated files with rubocop"
  run "rubocop -a &>/dev/null"

  remove_file "app/javascript/packs/hello_react.jsx"
  remove_file "app/javascript/packs/hello_typescript.ts"
  run "mv app/javascript/packs/application.js app/javascript/packs/application.ts"

  say_info "Removing unused babel config generated by webpacker"
  apply_babel_config_changes
end

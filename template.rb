# frozen_string_literal: true

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

run <<~YARN.squish
  yarn add -s
  @types/node
  core-js
  regenerator-runtime
YARN

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

after_bundle do
  rails_command "webpacker:install:react"
  rails_command "webpacker:install:typescript"

  # rubocop:disable Layout/LineLength
  run "curl -L https://raw.githubusercontent.com/juliantrueflynn/webpacker_react_typescript_rails_template/master/.eslintignore > .eslintignore"
  run "curl -L https://raw.githubusercontent.com/juliantrueflynn/webpacker_react_typescript_rails_template/master/.eslintrc.json > .eslintrc.json"
  run "curl -L https://raw.githubusercontent.com/juliantrueflynn/webpacker_react_typescript_rails_template/main/.rubocop.yml > .rubocop.yml"
  # rubocop:enable Layout/LineLength
  run "rubocop -a &>/dev/null"

  run <<~YARN.squish
    yarn remove -s
    prop-types
    babel-plugin-transform-react-remove-prop-types
  YARN

  run "rm app/javascript/packs/hello_react.jsx"
  run "rm app/javascript/packs/hello_typescript.ts"
  run "mv app/javascript/packs/application.js app/javascript/packs/application.ts"
  run "mkdir app/javascript/src"

  # Remove babel-plugin-transform-react-prop-types from babel config
  gsub_file(
    "babel.config.js",
    /,\s+isProductionEnv && \[.*'babel-plugin-transform-react-remove-prop-types'.*\]/ms,
    "\n    ]"
  )
end

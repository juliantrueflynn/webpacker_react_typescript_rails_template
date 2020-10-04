# webpacker_react_typescript_rails_template

Opinionated way to generate Rails app using Webpacker, React, and Typescript.
It provides React with a similar developer experience to create-react-app.

## Usage

This is a Rails template and so it can be generated like any Rails template.
Run the following command in terminal:

```sh
# At minimum we need the following command with flags, you can add any other flags you want on top of this.
rails n your_app -T -m https://github.com/juliantrueflynn/webpacker_react_typescript_rails_template/blob/master/template.rb
```

## What is included?

#### For Rails:
- Sets up RSpec test suite with: Capybara/Selenium, FactoryBot, Faker, ShouldaMatcher, SimpleCov, Webmock
- Sets up linting with Rubocop, using rubocop-rails, and provides some basic defaults

#### For React and Typescript:

The goal was to provide similar developer experience to create-react-app, and so most of the same libraries are used.

- Sets up ESLint and Prettier, including plugins for React
- `husky` and `lint-staged` for automatic linting/formatting
- Testing tools: `@testing-library/react`, `@testing-library/jest-dom`, `@testing-library/user-event`
- `@pmmmwh/react-refresh-webpack-plugin` and `fast-refresh` for hot module reloading

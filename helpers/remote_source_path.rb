# frozen_string_literal: true

require "shellwords"
require "tmpdir"
require "fileutils"

# When remote link is used with Rails generator `-m` flag, it breaks Thor's source_path.
# Cloning the GH repo to a temp directory to use as reference is a way to get around this.
# Heavily inspired (i.e. mostly copied) from: https://github.com/mattbrictson/rails-template
class RemoteSourcePath
  REPO_SLUG = "webpacker_react_typescript_rails_template"
  REPO_URL = "https://github.com/juliantrueflynn/#{REPO_SLUG}.git"
  TEMP_DIRECTORY_NAME = "_temp_#{REPO_SLUG}"
  TEMPLATE_FILE = "template.rb"

  def initialize(source_paths, path)
    @source_paths = source_paths
    @path = path
  end

  def add_path
    @source_paths.unshift(temp_directory)
    at_exit { FileUtils.remove_entry(temp_directory) }
    build_git_clone
    Dir.chdir(temp_directory) { git checkout: git_branch } if (git_branch)
  end

  private

  def temp_directory
    @_temp_directory ||= Dir.mktmpdir(TEMP_DIRECTORY_NAME)
  end

  def build_git_clone
    git clone: ShellWords.join(["--quiet", REPO_URL, temp_directory])
  end

  def git_branch
    @path[%r{#{REPO_SLUG}/(.+)/#{TEMPLATE_FILE}}, 1]
  end
end


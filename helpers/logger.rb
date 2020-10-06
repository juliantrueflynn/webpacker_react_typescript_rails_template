# frozen_string_literal: true

module Logger
  def say_info(message)
    say "-------------------------------------------------------------------------", :blue
    say message, :blue
    say "-------------------------------------------------------------------------", :blue
  end
end

require "./anticipate/runner"

# http://www.rkoucha.fr/tech_corner/pty_pdip.html

module Anticipate
  VERSION = "0.1.0"

  def self.spawn(command : String, verbose = false, file = __FILE__, line = __LINE__)
    yield Runner.new(command)
    puts "Finished running `#{command}` successfully!"
    true
  rescue ex : Runner::StopException
    puts ex.message || ex.cause
    false
  end
end

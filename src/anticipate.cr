require "./anticipate/dsl"

# http://www.rkoucha.fr/tech_corner/pty_pdip.html

module Anticipate
  VERSION = "0.1.0"

  def self.spawn(command : String)

    DSL.new(command)
  end
end

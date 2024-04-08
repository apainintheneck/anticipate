require "./pty"
require "./interaction"

module Anticipate
  class DSL
    def initialize(@interactions_list : Array(Interaction))
    end

    def send(message : String | Regex)
      @interactions_list << Interaction.new(
        type: Interaction::Type::Send,
        message: message
      )
    end

    def receive(message : String | Regex)
      @interactions_list << Interaction.new(
        type: Interaction::Type::Receive,
        message: message
      )
    end
  end
end

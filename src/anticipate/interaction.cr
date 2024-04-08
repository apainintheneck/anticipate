class Interaction
  enum Type
    Send
    Receive
  end

  getter type : Type

  def initialize(@type, @message : String | Regex)
  end
end

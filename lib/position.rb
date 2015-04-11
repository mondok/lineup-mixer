class Position
  attr_accessor :player
  attr_accessor :position_name

  def initialize
    yield self if block_given?
  end
end

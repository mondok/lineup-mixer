class PlayerForGame
  attr_accessor :name

  attr_accessor :batting_pos

  def initialize(total_innings)
    yield self if block_given?

    @total_innings = total_innings
    1.upto(@total_innings) do |i|
      varname = "inning_#{i}"
      define_singleton_method(varname) do
        instance_variable_get("@#{varname}")
      end

      define_singleton_method("#{varname}=") do |x|
        instance_variable_set("@#{varname}", x)
      end
    end
  end

  def to_s
    arr = [@batting_pos, @name]
    1.upto(@total_innings) do |i|
      val = send("inning_#{i}")
      arr << val
    end
    arr.join(',')
  end
end

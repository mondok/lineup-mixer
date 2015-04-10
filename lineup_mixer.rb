#!/usr/bin/env ruby

require 'yaml'

settings_from_disk = YAML.load_file('settings.yml')

kids          = settings_from_disk['players'].split(',').shuffle
positions     = settings_from_disk['positions'].split(',').shuffle
total_games   = settings_from_disk['total_games'] || 16
max_mixups    = settings_from_disk['overlap_allowance'] || 9
file_folder   = settings_from_disk['output_folder'].chomp('/')
total_innings = settings_from_disk['innings_per_game'] || 9

Settings = Struct.new(:kids, :positions, :total_games, :max_mixups, :file_folder, :total_innings)

global_settings = Settings.new(kids, positions, total_games, max_mixups, file_folder, total_innings)

class Game
  attr_accessor :innings

  def initialize
    @innings = []
  end
end

class Position
  attr_accessor :player
  attr_accessor :position_name

  def initialize
    yield self if block_given?
  end
end

class Inning
  attr_accessor :positions

  def initialize
    @positions = []
  end
end

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

class GameBuilder
  def initialize(settings)
    @settings = settings
  end

  def build!
    loop do
      mixups, games = games_list
      if mixups < @settings.max_mixups
        save(games)
        puts "Total overlap errors are #{mixups}"
        break
      end
    end
  end

  private
  def positions_for_kid(kid, innings)
    pos = []
    innings.each do |i|
      pos = pos + i.positions.select { |p| p.player == kid }.map { |p| p.position_name }
    end
    pos.flatten
  end

  def games_list
    mixups = 0
    games  = []
    1.upto(@settings.total_games) do |g|
      game = Game.new
      1.upto(@settings.total_innings) do
        taken_positions = []
        inning          = Inning.new
        @settings.kids.shuffle.each do |kid|
          taken_tmp      = taken_positions + positions_for_kid(kid, game.innings)
          available      = @settings.positions.select { |p| !taken_tmp.include?(p) }
          found_position = available.sample
          if !found_position
            found_position = (@settings.positions - taken_positions).shuffle.first
            mixups         += 1
          end
          position = Position.new do |p|
            p.player        = kid
            p.position_name = found_position
          end
          inning.positions << position
          taken_positions << found_position
        end
        game.innings << inning
      end
      games << game
    end
    return mixups, games
  end

  def save(games)
    games.each_with_index do |g, i|
      players = []
      @settings.kids.rotate(i*-1).each_with_index do |k, ki|
        p = PlayerForGame.new(@settings.total_innings) do |ply|
          ply.batting_pos = ki + 1
          ply.name        = k
        end

        g.innings.each_with_index do |inning, index|
          pos = inning.positions.select { |x| x.player == p.name }.first.position_name
          p.send(:"inning_#{index+1}=", pos)
        end
        players << p
      end
      write_to_disk(players, i+1)
    end
  end

  def write_to_disk(players, game_id)
    File.open("#{@settings.file_folder}/game_#{game_id}.csv", 'w') do |file|
      header = ['Order', 'Player']
      1.upto(@settings.total_innings) do |inn_idx|
        header << "Inning #{inn_idx}"
      end
      file.puts(header.join(','))
      players.sort { |a, b| a.batting_pos <=> b.batting_pos }.each do |p|
        file.puts(p.to_s)
      end
    end
  end
end

GameBuilder.new(global_settings).build!

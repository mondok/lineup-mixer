#!/usr/bin/env ruby

require 'yaml'

settings = YAML.load_file('settings.yml')

@kids = settings['players'].split(',').shuffle
@positions = settings['positions'].split(',').shuffle
@total_games = settings['total_games'] || 16
@max_mixups = settings['overlap_allowance'] || 9
@file_folder = settings['output_folder'].chomp('/')
$total_innings = settings['innings_per_game'] || 9

class Game
  attr_accessor :innings

  def initialize
    @innings = []
  end
end

class Position
  attr_accessor :player
  attr_accessor :position_name
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

  def initialize
    class << self
      1.upto($total_innings) do |i|
        attr_accessor("inning_#{i}")
      end
    end
  end

  def to_s
    arr = [@batting_pos, @name]
    1.upto($total_innings) do |i|
      val = send("inning_#{i}")
      arr << val
    end
    arr.join(',')
  end
end

def positions_for_kid(kid, innings)
  pos = []
  innings.each do |i|
    pos = pos + i.positions.select{|p| p.player == kid}.map{|p| p.position_name}
  end
  pos.flatten
end

def games_list
  mixups = 0
  games = []
  0.upto(@total_games) do |g|
    game = Game.new
    inn_max = $total_innings
    1.upto(inn_max) do |i|
      taken_positions = []
      inning = Inning.new
      @kids.shuffle.each do |kid|
        takens = taken_positions + positions_for_kid(kid, game.innings)
        available = @positions.select{|p| !takens.include?(p)}
        pos = available.sample
        if !pos
          pos = (@positions - taken_positions).shuffle.first
          mixups += 1
        end
        position = Position.new
        position.player = kid
        position.position_name = pos
        inning.positions << position
        taken_positions << pos
      end
      game.innings << inning
    end
    games << game
  end
  return mixups, games
end

def write_games_to_disk(games)
  games.each_with_index do |g, i|
    players = []
    @kids.rotate(i*-1).each_with_index do |k, ki|
      p = PlayerForGame.new
      p.batting_pos = ki + 1
      p.name = k
      g.innings.each_with_index do |inning, index|
        pos = inning.positions.select{|x| x.player == p.name}.first.position_name
        p.send(:"inning_#{index+1}=", pos)
      end
      players << p
    end
    File.open("#{@file_folder}/game_#{i+1}.csv", 'w') do |file|
      header = ['Batting Order', 'Player']
      1.upto($total_innings) do |inn_idx|
        header << "Inning #{inn_idx}"
      end
      file.puts(header.join(','))
      players.sort{|a,b| a.batting_pos <=> b.batting_pos}.each do |p|
        file.puts(p.to_s)
      end
    end
  end
end

def build!
  loop do
    mixups, games = games_list
    if mixups < @max_mixups
      write_games_to_disk(games)
      puts "TOTAL MIXUPS #{mixups}"
      break
    end
  end
end

build!

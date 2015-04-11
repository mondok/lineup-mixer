#!/usr/bin/env ruby

require 'yaml'
require './lib/game'
require './lib/inning'
require './lib/position'
require './lib/player_for_game'
require './lib/game_builder'
require './lib/settings'

settings = Settings.load
GameBuilder.new(settings).build!

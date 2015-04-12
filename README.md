# Lineup Mixer
Lineup Mixer is a Ruby script that will automatically generate random batting lineups for baseball and softball teams.  This is targeted towards youth sports where the kids are learning to play different positions - hence the randomization.

## Running
Copy the `settings.yml.sample` to `settings.yml` and fill in the values.  One thing to note is the `overlap_allowance` variable:  this variable is basically the allowable error rate, which means over the course of n games, a child may have to play a position twice in one game.

To run:

    ruby lineup_mixer.rb

This will create n CSV files in the specified output_folder directory.

## WIP
I honestly wrote this as a 1-time thing, but I think there's value in it for anyone else coaching youth baseball or softball.

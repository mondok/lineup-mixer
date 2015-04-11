GameSettings = Struct.new(:players, :positions, :total_games, :max_mixups, :file_folder, :total_innings)

module Settings
  module_function

  def load
    settings_from_disk = YAML.load_file('settings.yml')
    players       = settings_from_disk['players'].split(',').shuffle
    positions     = settings_from_disk['positions'].split(',').shuffle
    total_games   = settings_from_disk['total_games'] || 16
    max_mixups    = settings_from_disk['overlap_allowance'] || 9
    file_folder   = settings_from_disk['output_folder'].chomp('/')
    total_innings = settings_from_disk['innings_per_game'] || 9
    GameSettings.new(players, positions, total_games, max_mixups, file_folder, total_innings)
  end
end

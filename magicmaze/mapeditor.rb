############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2008-2024 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'magicmaze/graphics'
require 'magicmaze/map'
require 'magicmaze/gameloop'
require 'magicmaze/editor/dungeonmaster'

require 'date'
require 'fileutils'

module MagicMaze

  module MapEditor
  ########################################
  # 
  class EditorLoop < GameLoop
    
    def initialize( game_config, savedir) #level = 1, player_status = nil )
      @game_config = game_config
      @graphics    = game_config.graphics
      @sound       = game_config.sound
      @input = @game_input  = Input::Control.new( self, :in_game )
      @game_delay  = 50
      @savedir = savedir
      @map_save_dir = @savedir + '/maps/'
      @map_dir_path = @graphics.get_data_dir_path_to('maps/') || 'data/maps/'

      @map = nil
      @player = nil
    end


    def start(filename = nil)
      @graphics.clear_screen
      filename ||= choose_level_to_load
      if filename then
        load_map_file( filename )
      else
        return
      end
      game_loop
    end

    def choose_level_to_load
      menu_items = [
        Dir[@map_dir_path + "mm_map.*"],
        Dir[@map_save_dir + "/*.map"],
      ]
      menu_items.flatten!
      menu_items.push "Exit"
      menu_hash = Hash.new
      menu_items.each{|f| menu_hash[File.basename(f)] = f }

      selection = @graphics.choose_from_menu( menu_hash.keys.sort, @input )
      if selection == "Exit" then
        selection=nil
      end
      return menu_hash[selection]
    end

    def get_modified_map_files
      Dir[@map_save_dir + "/*.map"]
    end

    def get_official_map_files
      Dir[@map_dir_path + "mm_map.*"]
    end

    def load_map_file(filename)
      @loaded_filename = filename
      @filemap = MagicMaze::FileMap.new(filename)
      @map = @filemap.to_gamemap

      if @loaded_filename.end_with?('.map')
        # Modified or non-standard map; save directly.
        @map_save_filename = File.basename(@loaded_filename)
      else
        datetimestr = DateTime.now.strftime('%Y%m%d') # WAS: %H%M')
        ext = File.extname(@loaded_filename).sub('.', '')
        @map_save_filename = 'mm' + ext + '_' + datetimestr + '.map'
      end

      @player = DungeonMaster.new( @map, self )
    end

    def save_map_file
      @filemap.from_gamemap(@map)
      @filemap.update_header_data
      FileUtils.mkdir_p(@map_save_dir)
      @filemap.save_to(@map_save_dir + (@map_save_filename || 'mm_modified.map'))
    end
    
    def save_game
      puts "SAVE MAP!"
      save_map_file
    end

    def escape
      super
      really_do?(_("Save modified map?")) do
        save_map_file
      end if @state == :stopped_game
    end

    def process_entities
      @player.action_tick
    end

    def start_editor_loop
      puts "Editor loop..."  
      @graphics.put_screen( :background, false, false )
      draw_now      
      @graphics.fade_in

      @state = :game_loop
      while @state == :game_loop

        draw_now

        @movement = 0
        @input.check_input
        calc_movement
        
      end
    end
    
  end # EditorLoop
  
  
  
  end # MapEditor

end # MagicMaze

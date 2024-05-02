############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2008-2010 Kent Dahl
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
      #@level = level
      #@restart_status = player_status

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
        Dir[@savedir+"/*.map"],
        Dir["data/maps/mm_map.*"]
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

    def load_map_file(filename)
      @load_filename = filename
      @filemap = MagicMaze::FileMap.new(filename)
      @map = @filemap.to_gamemap
      @player = DungeonMaster.new( @map, self )
    end

    def save_map_file
      @filemap.from_gamemap(@map)
      @filemap.update_header_data
      @filemap.save_to(@savedir+"/modified.map")
    end
    
    def save_game
      puts "SAVE MAP!"
      save_map_file
    end

    def process_entities
      @player.action_tick
      # game_data = { 
      #   :player_location => @player.location
      # }
      # @map.active_entities.each_tick( game_data )
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

############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2008 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'magicmaze/graphics'
require 'magicmaze/map'




module MagicMaze

  ########################################
  # 
  class MapEditor
    def initialize(game_config, savedir)
      @game_config = game_config
      @graphics = game_config.graphics
      @savedir = savedir
      @input = Input::Control.new( self, :in_game )
    end


    def start
      @graphics.clear_screen
      filename = choose_level_to_load
      if filename then
	load_map_file( filename )
      else
	return
      end
      start_editor_loop
    end

    def choose_level_to_load
      menu_items = [
	Dir["data/maps/mm_map.*"],
	Dir[@savedir+"/*.map"]
      ]
      menu_items.push "Exit"

      selection = @graphics.choose_from_menu( menu_items.flatten, @input )
      if selection == "Exit" then
	selection=nil
      end
      return selection
    end

    def load_map_file(filename)
      # if @map then maybe_save end'
      @filemap = MagicMaze::FileMap.new(filename)
      @gamemap = @filemap.to_gamemap
    end

    def save_map_file
    end
    

  end # MapEditor

end # MagicMaze

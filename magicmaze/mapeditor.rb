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
      @filemap = MagicMaze::FileMap.new(filename)
      @map = @filemap.to_gamemap
      @player = DungeonMaster.new( @map, self )
    end

    def save_map_file
    end
    
    
    def process_entities
      alive = @player.action_tick
      game_data = { 
        :player_location => @player.location
      }
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
  
  
  ##
  # The Dungeon Master - or map-editor player...
  class DungeonMaster < Player
    DM_SPELL_NAMES = {
      :primary => DEFAULT_ALL_OBJECT_TILES.keys.sort{|a,b| a.to_s<=>b.to_s},
      :secondary => DEFAULT_MONSTER_TILES.keys.sort{|a,b| a.to_s<=>b.to_s}
    }

    DM_CREATE_SPELL_TILES = DEFAULT_ALL_OBJECT_TILES
    DM_SUMMON_SPELL_TILES = DEFAULT_MONSTER_TILES
    
    def initialize( map, game_config, *args )
      super( map, game_config, *args )
      newlocation = SpiritualLocation.new( self, map, @location.x, @location.y )
      @location = newlocation
      @primary_spell = DM_CREATE_SPELL_TILES[DM_CREATE_SPELL_TILES.keys.first]
      @secondary_spell = DM_SUMMON_SPELL_TILES[DM_SUMMON_SPELL_TILES.keys.first]
      @spellbook = SpellBook.new( DM_CREATE_SPELL_TILES, DM_SUMMON_SPELL_TILES , DM_SPELL_NAMES )
    end
    def move_forward( *args )
      @location.add!( @direction )
    end
    def action_tick( *args )      
      follow_impulses      
      check_counters
    end
    
    def follow_impulses
      mf = @impulses[:move_forward]
      ta = @impulses[:turn_around]
      IMPULSES.each{|key|
        value = @impulses[key]
        if value then
          self.send(key, value)
          @impulses[key] = nil
          @last_action = key
        end
      }
    end
    
    def sprite_id
      ( @override_sprite || (@direction.value + MATURE_WIZARD_TILE_ID) )
    end

  end
  
  
    ### Default Spells in Spellbook ===


  
  end # MapEditor

end # MagicMaze

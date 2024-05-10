############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2010 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

module MagicMaze

  module MapEditor
  
  ########################################
  # The Dungeon Master - or map-editor player...
  #
  class DungeonMaster < Player
    DM_SPELL_NAMES = {
      :primary   => DEFAULT_ALL_OBJECT_TILES.keys.sort{|a,b| a.to_s<=>b.to_s },
      :secondary => DEFAULT_MONSTER_TILES.keys.sort{|a,b|    a.to_s<=>b.to_s }
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

  end # DungeonMaster


  end # MapEditor

end # MagicMaze

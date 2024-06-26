############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2024 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

module MagicMaze

  ##
  # Used to clarify interfaces that needs implementing.
  module Abstract
    def abstract_method_called
      raise ArgumentError, "Abstract method called."
    end
  end

  ########################################
  ## 
  # an object representing a simple
  # tile sprite in the game.
  #
  class Tile
    include Abstract
    attr_reader :sprite_id
    def initialize( sprite_id = nil )
      @sprite_id = sprite_id
    end

    ##
    # Used by the map editor (or Dungeon Master player)
    #
    def cast_spell( caster, *args )
      loc = caster.location
      dx, dy = caster.direction.to_2D_vector
      loc.map.set_any_object(loc.x + dx, loc.y + dy, self) rescue log_tile_error("Tile outside map!")
    end

    def log_tile_error(error, comment = nil)
      puts "TILE ERROR: " + error.to_s 
    end
  end

  ##
  # Man, I'm lazy...
  #
  module SuperInit
    def initialize(*a)
      super(*a)
    end      
  end

  class EntityTile < Tile
    include SuperInit
    def create_entity( *args )
      abstract_method_called
    end
    
    ##
    # Used by the map editor (or Dungeon Master player)
    def cast_spell( caster, *args )
      loc = caster.location
      dx, dy = caster.direction.to_2D_vector
      create_entity(loc.map, loc.x + dx, loc.y + dy)
    end
  end

  class MonsterTile < EntityTile
    def initialize(*args)
      @start_health = args.pop
      super(*args)
    end
    attr_reader :start_health
    def create_entity(map,x,y,*args)
      Monster.new(map,x,y, self)
    end

  end


  ########################################


  ## 
  # An in-game object tile type, 
  # such as keys, doors, etc.
  #
  class ObjectTile < Tile
    include SuperInit

    ## 
    # handle collision between an object on the floor
    # and the player.
    # Return true if the object has been "consumed"
    # and needs to be removed from the map.
    #
    def collide_with_player( *args )
      false
    end

    def collide_with_monster( *args )
      false
    end
    
  end

  class KeyTile < ObjectTile
    attr_reader :color
    def initialize( *args )
      @color = args.pop
      super( *args )
    end

    def collide_with_player( player, *args )
      result = player.inventory_add_key(@color) 
      player.play_sound( :bonus ) if result
      result 
    end
  end

  class BonusTile < ObjectTile
    def initialize(*args)
      @bonus = args.pop
      super(*args)
    end

    def collide_with_player( player, *args )
      player.play_sound( :bonus )
      player.increase_score( @bonus )      
      true
    end
  end

  class ManaRefillTile < ObjectTile
    def initialize(*args)
      @mana = args.pop
      super(*args)
    end

    def collide_with_player( player, *args )
      if player.mana <= Player::MAX_MANA-@mana
        player.play_sound( :bonus )
        player.add_mana( @mana )
        true
      else
        false
      end
    end
  end # ManaRefillTile


  class LifeRefillTile < ObjectTile
    def initialize(*args)
      @life = args.pop
      super(*args)
    end
    def collide_with_player( player, *args )
      if player.life <= Player::MAX_LIFE-@life
        player.play_sound( :bonus )        
        player.add_life( @life )
        true
      else
        false
      end
    end
  end

  class LifeManaRefillTile < ObjectTile
    def initialize(*args)
      @mana = args.pop
      @life = args.pop    
      super(*args)
    end
    def collide_with_player( player, *args )
      life_potential = Player::MAX_LIFE-player.life
      mana_potential = Player::MAX_MANA-player.mana
      if life_potential >= @life/4 and mana_potential >= @mana/4
        player.play_sound( :bonus )
        player.add_life( life_potential )
        player.add_mana( mana_potential )
        true
      else
        false
      end
    end

  end


  class ExitTile < ObjectTile
    def initialize(*args)
      super(*args)
    end

    def collide_with_player( player, *args )
      player.exit_to_next_level
      true
    end
  end



  class DoorTile < EntityTile
    attr_reader :color
    def initialize(*a)
      @color = a.pop
      super(*a)
    end
    def create_entity(map,x,y,*args)
      self
    end
    
    ##
    # Used by the map editor (or Dungeon Master player)
    def cast_spell( caster, *args )
      loc = caster.location
      dx, dy = caster.direction.to_2D_vector
      loc.map.set_any_object(loc.x + dx, loc.y + dy, self) rescue puts "Door outside map!"
    end

  end






  ##
  # a Tile that is part of the background
  #
  class BackgroundTile < Tile
    BACKGROUND_TILES_BEGIN = 58
    
    attr_reader :blocked
    alias :blocked? :blocked
   
    def initialize( sprite_id = 0, blocked = false )
      super( sprite_id + BACKGROUND_TILES_BEGIN )
      @blocked = blocked
    end


    ##
    # Used by the map editor (or Dungeon Master player)
    #
    def cast_spell( caster, *args )
      loc = caster.location
      dx, dy = caster.direction.to_2D_vector
      loc.map.set_background(loc.x + dx, loc.y + dy, self) rescue log_tile_error("Floor outside map!")
    end

  end





  ########################################


  ## 
  # Some default object tiles.
  #
  DEFAULT_KEY_TILES = {
    :red_key    => KeyTile.new(30, :red),
    :blue_key   => KeyTile.new(31, :blue),
    :yellow_key => KeyTile.new(32, :yellow),
  }
  DEFAULT_DOOR_TILES = {
    :RED_DOOR    => DoorTile.new(33, :red),
    :BLUE_DOOR   => DoorTile.new(34, :blue),
    :YELLOW_DOOR => DoorTile.new(35, :yellow),
  }

  DEFAULT_MONSTER_TOUGHNESS_ARRAY = [ 4, 13, 19, 25,  31, 38, 44, 51, 57, 63, 70, 76, 83, 89, 95, 101, 108, 114] # , 120, 127].
  DEFAULT_MONSTER_TILES = Hash.new
  DEFAULT_MONSTER_TOUGHNESS_ARRAY.each_with_index{|tough, index|    
    DEFAULT_MONSTER_TILES[ ("monster%02d"%index).intern ] = MonsterTile.new( 40 + index, tough )
  }


  DEFAULT_OBJECT_TILES = {
    :BLOOD_SPLAT => ObjectTile.new(9),
    :CHEST       => BonusTile.new(20, 50),
    :LIFE_POTION => LifeRefillTile.new(21, 25),
    :MANA_POTION => ManaRefillTile.new(22, 20),
    :MONEY_BAG   => BonusTile.new(23, 250),
    :ORB         => LifeManaRefillTile.new(24, 100, 100),

    
    :EXIT  => ExitTile.new(39),  
  }
  
  DEFAULT_ALL_OBJECT_TILES = Hash.new
  [ DEFAULT_OBJECT_TILES,
    DEFAULT_KEY_TILES,     
    DEFAULT_DOOR_TILES,
  ].each{|i| DEFAULT_ALL_OBJECT_TILES.update(i) }


  DEFAULT_FLOOR_TILES = Hash.new
  (0..29).each_with_index do |index|
    DEFAULT_FLOOR_TILES[ ("floor%02d"%index).intern ] = BackgroundTile.new(index)
  end

  ##
  # gather them all i DEFAULT_TILES
  #
  DEFAULT_TILES = Hash.new
  [ DEFAULT_OBJECT_TILES,
    DEFAULT_KEY_TILES,     
    DEFAULT_DOOR_TILES,
    DEFAULT_MONSTER_TILES,
    DEFAULT_FLOOR_TILES,
  ].each{|i| DEFAULT_TILES.update(i) }

  ##
  # Create reverse lookup hash for tiles.
  # No two tiles may have same sprite id!
  #
  DEFAULT_TILES_ID_LOOKUP = Hash.new
  DEFAULT_TILES.each{|key,value|
    DEFAULT_TILES_ID_LOOKUP[ value.sprite_id ] = value
  }

  ANCIENT_WIZARD_TILE_ID = 0
  MATURE_WIZARD_TILE_ID = 26
  YOUNG_WIZARD_TILE_ID  = 26

end

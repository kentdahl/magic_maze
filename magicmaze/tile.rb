
module MagicMaze

  module Abstract
    def abstract_method_called
      raise ArgumentError, "Abstract method called."
    end
  end

  ########################################
  ## 
  # an object representing a simple
  # tile sprite in the game.
  class Tile
    include Abstract
    attr_reader :sprite_id
    def initialize( sprite_id = nil )
      @sprite_id = sprite_id
    end
  end

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
  class ObjectTile < Tile
    include SuperInit

    ## 
    # handle collision between an object on the floor
    # and the player.
    # Return true if the object has been "consumed"
    # and needs to be removed from the map.
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
  end






  ##
  # a Tile that is part of the background
  class BackgroundTile < Tile
    BACKGROUND_TILES_BEGIN = 58
    
    attr_reader :blocked
    alias :blocked? :blocked
   
    def initialize( sprite_id = 0, blocked = false )
      super( sprite_id + BACKGROUND_TILES_BEGIN )
      @blocked = blocked
    end
  end



  ########################################
  ## 
  # Spell tiles. For the Spellbook.
  class SpellTile < Tile
    def initialize(*a)
      @mana_cost = a.pop
      super(*a)
    end

    def have_mana?
      @caster.have_mana?( @mana_cost )
    end

    def use_mana?
      @caster.use_mana( @mana_cost )
    end
    def restore_mana
      @caster.use_mana( - @mana_cost )
    end
    protected :use_mana?
    
    ##
    # Cast a spell if there is enough mana.
    # Restore the mana if the spell fails.
    # The actual magic is relegated to do_magic.
    def cast_spell( caster, *args )
      @caster = caster
      if have_mana? then 
        do_magic and caster.add_mana( -@mana_cost )
      end
    end      

    ##
    # Return a true value if magic was done.
    def do_magic
      abstract_method_called
    end

  end

  class AttackSpellTile < SpellTile
    attr_reader :damage
    def initialize(*a)
      @damage = a.pop
      @missiles = Array.new
      super(*a)
    end
    def do_magic 
      return false if @missiles.size > 3 
      location = @caster.location
      # puts "Caster",location.map, location.x, location.y
      @caster.play_sound( :zap )
      missile = Missile.new( @caster, location.map, location.x, location.y, self  )
      # location.map.spiritual.set(  location.x, location.y, missile )
      location.map.add_active_entity( missile )
      @missiles.push( missile )
      true
    end
    def remove_missile( missile )
      @missiles.delete( missile )
    end
  end



  class MagicMapSpellTile < SpellTile
    include SuperInit
    def do_magic 
      @caster.game_config.graphics.draw_map( @caster )
      @caster.game_config.input.get_key_press # Release of trigger...
      @caster.game_config.input.get_key_press # And another push to return.
      true
    end
  end
  
  class HealSpellTile < SpellTile
    def initialize(*a)
      @heal_gain = a.pop
      super(*a)
    end
    def do_magic 
      @caster.heal( @heal_gain )
    end
  end

  class SummonManaSpellTile < SpellTile
    def initialize(*a)
      @mana_gain = a.pop
      @heal_cost = a.pop
      super(*a)
    end
    def cast_spell( caster, *args )
      if  caster.life > @heal_cost +  Player::MAX_LIFE >> 2 and 
          caster.mana + @mana_gain <= Player::MAX_MANA 
      then 
        caster.add_life( -@heal_cost )
        caster.add_mana( @mana_gain )
        true
      else
        false
      end
    end      


  end

  class SpyEyeSpellTile < SpellTile
    include SuperInit    
    def do_magic 
      false # TODO
    end

  end



  ########################################
  ## 
  # Some default object tiles.
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

  DEFAULT_MONSTER_TILES = Hash.new
  [ 4, 13, 19, 25,  31, 38, 44, 51, 57, 63, 70, 76, 83, 89, 95, 101, 108, 114, 120, 127].
    each_with_index{|tough, index|    
    DEFAULT_MONSTER_TILES[ ":monster#{index}".intern ] = MonsterTile.new( 40 + index, tough )
  }

  DEFAULT_ATTACK_SPELL_TILES = {
    :spell_lightning => AttackSpellTile.new( 10, 1,  4),
    :spell_bigball   => AttackSpellTile.new( 11, 2,  9),
    :spell_coolcube  => AttackSpellTile.new( 12, 4, 20),
  }

  DEFAULT_OTHER_SPELL_TILES = {
    :spell_magic_map      => MagicMapSpellTile.new( 13, 1 ),
    :spell_heal           => HealSpellTile.new( 14, 2, 2 ),
    :spell_summon_mana    => SummonManaSpellTile.new( 15, 0, 3, 2 ),
    :spell_spy_eye        => SpyEyeSpellTile.new( 16, 1 ),
    # :spell_x2              => SpellTile.new( 18 ),
  }


  DEFAULT_TILES = {
    :BLOOD_SPLAT => ObjectTile.new(9),
    :CHEST       => BonusTile.new(20, 50),
    :LIFE_POTION => LifeRefillTile.new(21, 25),
    :MANA_POTION => ManaRefillTile.new(22, 20),
    :MONEY_BAG   => BonusTile.new(23, 250),
    :ORB         => LifeManaRefillTile.new(24, 100, 100),

    
    :EXIT  => ExitTile.new(39),  
  }
  # gather them all i DEFAULT_TILES
  [ DEFAULT_KEY_TILES,     
    DEFAULT_DOOR_TILES,
    DEFAULT_MONSTER_TILES,
    DEFAULT_ATTACK_SPELL_TILES,
    DEFAULT_OTHER_SPELL_TILES,
  ].each{|tileset|
    DEFAULT_TILES.update( tileset )
  }

  # Create reverse lookup hash for tiles.
  # No two tiles may have same sprite id!
  DEFAULT_TILES_ID_LOOKUP = Hash.new
  DEFAULT_TILES.each{|key,value|
    DEFAULT_TILES_ID_LOOKUP[ value.sprite_id ] = value
  }

end

############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2008 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'magicmaze/movement'
require 'magicmaze/game'
require 'magicmaze/spellbook'
require 'magicmaze/inventory'


module MagicMaze

  ##################################################
  # Game object representing the player.
  class Player < Being
    attr_reader :impulses
    attr_reader :spellbook

    IMPULSES = [ :move_forward, :turn_around, :die ]

    attr_reader :score
    attr_reader :inventory
    
    attr_reader :life, :mana


    START_MANA = 100
    START_LIFE = 100

    GAIN_MANA_DELAY = 24
    LOOSE_HEALTH_DELAY = 256

    attr_reader :game_config

    def initialize( map, game_config, *args )
      super( map, map.start_x, map.start_y, *args )
      print "init: Player#location: ", @location.x, " ", @location.y, "\n"

      @game_config = game_config
      @score = 0
      @primary_spell = DEFAULT_ATTACK_SPELL_TILES[:spell_lightning]
      @secondary_spell = DEFAULT_OTHER_SPELL_TILES[:spell_magic_map]
      @inventory = Inventory.new
      @spellbook = SpellBook.new
      @mana = START_MANA
      @life = START_LIFE

      @impulses = Hash.new
      @last_action = nil

      @gain_mana_delay = GAIN_MANA_DELAY
      @loose_health_delay = LOOSE_HEALTH_DELAY

      @override_sprite = nil
    end

    def reset( map, saved = nil )
      if map
        @location.delete # Necessary to release the player entity from the grid.
        @location = EntityLocation.new( self, map, map.start_x, map.start_y )
      end

      if saved
	@mana = saved[:mana]
	@life = saved[:life]
	@score = saved[:score]
      end

      @mana = [ @mana, START_MANA ].max
      @life = [ @life, START_LIFE ].max

      @inventory = Inventory.new # Flush inventory

      @impulses = Hash.new
      @last_action = nil 

      @override_sprite = nil
    end

    ##
    # return hash with saved game status... Only restart point of level so far.
    def get_saved
      {
	:mana => @mana,
	:life => @life,
	:score=> @score
      }      
    end


    ##################################################
    # Impulses
    def move_forward( *args )
      if super
        # movement successful
      else
        # try unlocking keys?
        location = @location.to_maplocation + @direction
        entity = location.get(:entity) if location
        case entity
        when DoorTile
          opened = @inventory.open_door?( entity.color )
          location.set(:entity,nil) if opened
        end
      end
    end

    def turn_around( direction )
      @direction.value = direction
    end
    

    ##################################
    # Action ticks - what to check 
    # each and every game tick.
    def action_tick( *args )      
      follow_impulses      
      check_floor
      check_nearby_monsters
      check_counters
    end
    
    def follow_impulses
      mf = @impulses[:move_forward]
      ta = @impulses[:turn_around]
      if mf and ta then
        ta_ok = (@location.to_maplocation + Direction.new(ta))
        mf_ok = (@location.to_maplocation + @direction)
        if ta_ok 
          if mf_ok
            @impulses[@last_action]  = nil 
          else
            @impulses[:move_forward] = nil
          end
        else
          if mf_ok
            @impulses[:turn_around] = nil
          else
            # uh ...
            @impulses[:turn_around] = nil
          end
        end
      end
      IMPULSES.each{|key|
        value = @impulses[key]
        if value then
          self.send(key, value)
          @impulses[key] = nil
          @last_action = key
        end
      }
    end

    def add_impulse( impulse, value=true )
      @impulses[impulse] = value
    end


    def check_floor
      entity = @location.get(:object)
      if entity
        consumed = entity.collide_with_player( self )
        @location.set(:object,nil) if consumed
      end
    end
    
    
    def check_nearby_monsters
      ox, oy = *(@location.to_a)
      Direction::COORDINATE_VECTORS.each{|dx,dy|
        x = ox + dx
        y = oy + dy        
        entity = @location.map.entity.get(x, y)        
        if (entity and entity.kind_of? Monster and entity.alive?) then 
          play_sound( :punch )
          loose_health( 1 )
        end
      }
    end

    def check_counters
      @gain_mana_delay -= 1
      if( @gain_mana_delay < 0 )
        add_mana( 1 )
        @gain_mana_delay = GAIN_MANA_DELAY
      end
      @loose_health_delay -= 1
      if( @loose_health_delay < 0 )
        loose_health( 1 )
        @loose_health_delay = LOOSE_HEALTH_DELAY
      end
    end

    def increase_score( diff )
      @score += diff
      true
    end

    def loose_health( diff )
      add_life( -diff )
      if @life <= 0 then
        play_sound( :argh )
        @override_sprite = DEFAULT_TILES[ :BLOOD_SPLAT ].sprite_id
        add_impulse( :die )
      end
    end

    def die( vale )
      request_state_change( :player_died )
    end

    def heal( diff )
      if @life + diff <= MAX_LIFE
        add_life( diff )
        true
      else
        false
      end
    end

    def have_mana?( diff )
      if @mana >= diff
        true
      else
        false
      end
    end


    # callback from missiles.
    def missile_removed( missile )
      # @num_missiles -= 1
    end

    def sprite_id
      ( @override_sprite || @direction.value )
    end

    def inventory_add_key( key )
      result = @inventory.add_key( key )
      result
    end


    def play_sound( sound )
      @game_config.sound.play_sound( sound )
    end

    ##
    # tell gameloop to inc the level number
    def exit_to_next_level
      request_state_change( :next_level )
    end

    def request_state_change( state )
      throw :state_change, state
    end

  end # Player

end

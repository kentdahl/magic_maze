require 'magicmaze/movement'
require 'magicmaze/game'
require 'magicmaze/tile'

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


    START_MANA = 81
    START_LIFE = 13

    def initialize( map, game_config, *args )
      super( map, map.start_x, map.start_y, *args )
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
    end

    def reset( map )
      @location = EntityLocation.new( self, map, map.start_x, map.start_y )

      @mana = [ @mana, START_MANA ].max
      @life = [ @life, START_LIFE ].max

      @inventory = Inventory.new # Flush inventory

      @impulses = Hash.new
      @last_action = nil     
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


    def deprecated_use_mana( diff )
      if @mana >= diff
        add_mana( -diff )
        true
      else
        false
      end
    end

    def deprecated_restore_mana( diff )
      if @mana + diff <= MAX_MANA then
        add_mana( diff )
        true
      else
        false
      end
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


    class SpellBook
      SPELL_NAMES = {
        :primary => [:spell_lightning, :spell_bigball, :spell_coolcube],
        :secondary => [:spell_heal, :spell_summon_mana, :spell_magic_map, :spell_spy_eye]
      }
        
      ##
      # takes two hashes containing spell tiles.
      def initialize( primary_spells  = DEFAULT_ATTACK_SPELL_TILES, 
                     secondary_spells = DEFAULT_OTHER_SPELL_TILES )
        @spell_list = Hash.new
        tiles = nil
        insertion = proc {|spell_name| 
          @spell_list[ spell_name ] = tiles[spell_name] 
        }
        tiles = primary_spells
        SPELL_NAMES[:primary].each &insertion
        tiles = secondary_spells
        SPELL_NAMES[:secondary].each &insertion
        #:primary => primary_spells,
        #  :secondary => secondary_spells
        #}
        @spell_index = Hash.new(0)
      end

      def spell( spell_type = :primary )
        @spell_list[
          SPELL_NAMES[spell_type][ @spell_index[spell_type]] 
        ]
      end
      def primary_spell
	spell( :primary )
      end
      def secondary_spell
        spell( :secondary )
      end

      def page_spell( spell_type = :primary, diff = 1 )
        @spell_index[ spell_type ] += diff
        bound_index!( spell_type )
      end

      def bound_index!( spell_type = :primary )
        index = @spell_index[ spell_type ]
        max = SPELL_NAMES[ spell_type ].size
        index = if index<0
                  max + index
                else
                  if index>= max
                    index - max
                  else
                    index
                  end
                end
        @spell_index[ spell_type ] = index
        nil
      end
      private :bound_index!


      # callback from missiles.
      def missile_removed( missile )

      end
      

    end

  end # Player





  ##
  # the backpack of our ol' wizard.
  class Inventory
    MAX_KEYS = 3
    tiles = DEFAULT_KEY_TILES
    KEY_TILES = Hash.new
    tiles.each{|hashkey, keytile|
      KEY_TILES[keytile.color] = keytile
    }
    #  :red =>    tiles[:red_key],
    #  :blue =>   tiles[:blue_key], 
    #  :yellow => tiles[:yellow_key]
    #}
    def initialize
      @keys = Hash.new(0)
    end
    def add_key( color )
      have = @keys[color]
      if have<MAX_KEYS
        @keys[color]+=1
      else
        nil
      end
    end

    def each
      KEY_TILES.each{|key, tile|
        @keys[key].times{
          yield tile.sprite_id
        }
      }
    end

    def open_door?( color )
      if @keys[color]>0
        @keys[color]-=1
        true
      else
        false
      end
    end

  end # Inventory

end

require 'magicmaze/movement'

module MagicMaze

  ###############################
  # Basic game objects.

  class Entity
    attr_reader :location
    def initialize( map = nil, x = 0, y = 0, tile = nil )
      @location = EntityLocation.new( self, map, x, y )
      @tile = tile
    end
    def sprite_id
      (@tile ? @tile.sprite_id : 0)
    end
    def active?
      true
    end

    ##
    # try to move in the facing direction
    def move_forward(*a)
      @location.add!( @direction )
    end


  end

  class Being < Entity
    MAX_LIFE = MAX_MANA = 100

    attr_reader :direction
    def initialize( *args )
      super(*args)
      @direction = Direction.new
    end


    ##
    # a short method called every chance the Being
    # may do an action, such as move, turn etc.
    def action_tick( *args )

    end


    def add_life( diff )
      old_life = @life
      @life += diff
      @life = MAX_LIFE if @life > MAX_LIFE

      if @life <= 0
	@life = 0
	location.remove_old_entity
	unless location.get(:object)
	  location.set(:object,  DEFAULT_TILES[ :BLOOD_SPLAT ])
	end
	(old_life > 0 ? :died : :dead) 
      end
    end


    def add_mana( diff )
      @mana += diff
      @mana = 0 if @mana < 0
      @mana = MAX_MANA if @mana > MAX_MANA
    end

    def alive?
      @life > 0
    end

    def active?
      alive?
    end

  end # Being



  class Door < Entity
    def initialize( *args )
      super(*args)
    end
  end

  ###############################
  # Missiles, such as attack spells
  class Missile < Entity

    def initialize( caster, map = nil, x = 0, y = 0, tile = nil )
      @location = SpiritualLocation.new( self, map, x, y )
      @tile = tile
      @caster = caster
      @direction = @caster.direction.dup
      @active = true
      @movements = 10 # How far the missile goes.
    end

    def action_tick( *args )
      return unless @active
      backgorund =  @location.get(:background)
      entity     =  @location.get(:entity)
      if @location.get(:background).blocked?
	remove_missile
      elsif entity and entity != @caster 
	hit_entity( entity )
      else
	@movements -= 1
	remove_missile if not move_forward or @movements < 1 
      end
     
    end

    def hit_entity( entity )
      if entity.kind_of?(Monster) && entity.add_life( -@tile.damage ) == :died
	# puts "SMACK! #{entity.alive?}"
	@caster.play_sound( :argh ) 
	@caster.increase_score( 10 ) # whats the value again?
      end
      remove_missile
    end

    def remove_missile
      @tile.remove_missile( self )
      @active = false
      @location.remove_old_entity
    end

    def active?
      @active
    end
  end


  ###############################
  # Monsters
  #
  class DumbMonster < Being
    def initialize( map, x, y, tile )
      super( map, x, y, tile )
      @life = tile.start_health
      @sleep = 8
    end

    def action_tick( *args )           
      @sleep -= 1
      if @sleep < 0    
        ox = @location.x
        oy = @location.y
        was_moved = move_forward
        if was_moved
          # puts "Monster#action_tick - #{@location.x-ox}, #{@location.y-oy}"
          @sleep = 8
        else
          @direction.rotate_clockwise
          @sleep = 4
        end
      end

    end # action_tick

  end


  ##
  # Monster moving fairly close to the original Magic Maze monsters.
  # Translated the Pascal code almost directly.
  #
  class OriginalMotionMonster < Being
    def initialize( map, x, y, tile )
      super( map, x, y, tile )
      @life = tile.start_health
      @sleep = 8
    end

    def action_tick( *args )           
      @sleep -= 1
      if @sleep < 0    
	attempt_movement( *args )
      end
    end

    def attempt_movement( game_data = {}, *args )

      # Monster location
      mx = @location.x
      my = @location.y

      # Player location
      ploc = game_data[:player_location] || @location
      px = ploc.x
      py = ploc.y

      jp = Direction::COMPASS_DIRECTIONS.collect{|i| rand(35) + 175 }  #  FOR j:=0 TO 3 DO jp[j]:=0+Random(35)+175;

      if ( py < my ) 
	jp[0] += 1000
	jp[2] -= 200
      end
      if ( py > my ) 
	jp[2] += 1000
	jp[0] -= 200
      end
      if ( px > mx ) 
	jp[1] += 1000
	jp[3] -= 200
      end
      if ( px < mx ) 
	jp[3] += 1000
	jp[1] -= 200
      end

      mp = -3000
      m = -1
      jp.each_with_index {|desire, curr_direction|
	if direction == @direction.value 
	  desire += 15 # Prefer to go straight
	end

	# if blocked, set desire = 0
	location = @location.to_maplocation + Direction.get_constant( curr_direction )
	if location and not @location.allowed_access_to?( location.x, location.y )
	  desire = 0
	end
	if not location
	  puts "Orig Location(#{@location.x}, #{@location.y}) - #{direction}"
	end


	if desire > mp # Store the direction we desire the most.
	  mp = desire
	  m = curr_direction	  
	end
      }

      if mp > 0
	@direction = Direction.get_constant( m )
	was_moved = move_forward
	if was_moved
	  @sleep = 8
	end
      end #

    end 

  end # OriginalMotionMonster 


  Monster = OriginalMotionMonster


end

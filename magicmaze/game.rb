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
	puts "SMACK! #{entity.alive?}"
	@caster.play_sound( :argh ) 
	@caster.increase_score( 1 ) # whats the value again?
      end
      remove_missile
    end

    def remove_missile
      @caster.missile_removed( self )
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
  class Monster < Being
    def initialize( map, x, y, tile )
      super( map, x, y, tile )
      @life = tile.start_health
      puts "Monster life: #@life"
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


end

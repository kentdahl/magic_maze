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
  end

  class Being < Entity
    MAX_LIFE = MAX_MANA = 100

    attr_reader :direction
    def initialize( *args )
      super(*args)
      @direction = Direction.new
    end

    ##
    # try to move in the facing direction
    def move_forward(*a)
      @location.add!( @direction )
    end


    ##
    # a short method called every chance the Being
    # may do an action, such as move, turn etc.
    def action_tick( *args )

    end


    def add_life( diff )
      @life += diff
      @life = 0 if @life < 0
      @life = MAX_LIFE if @life > MAX_LIFE
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
    def sprite_id
      (@tile ? @tile.sprite_id : 0)
    end
  end



  class Monster < Being
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
    end

  end


end

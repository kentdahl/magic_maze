module MagicMaze

  ##
  # a 2D location
  class Location
    attr_reader :x, :y
    def initialize( x = 0, y = 0 )
      set_coords!(x,y)
    end

    ##
    # this is the only method that is allowed to alter the 
    # value of the location!
    # It must return a value that evaluates to true 
    # if coordinates were altered and false if not.
    # 
    def set_coords!( x, y )
      @x = x
      @y = y
      self
    end

    def add!( diff )
      case diff
      when Location
        dx = diff.x
        dy = diff.y
      when Direction
        dx, dy = diff.to_2D_vector
      else
        raise ArgumentError, "Could not add #{diff.class} to Location."
      end
      set_coords!( @x+dx, @y+dy )
    end

    def +( diff )
      self.dup.add!(diff)
    end

    def to_a
      [@x, @y]
    end


  end # Location


  ##
  # a 2D location inside and constrained by a map.
  class MapLocation < Location
    attr_reader :map
    def initialize( map, *args)
      @map = map
      super(*args)
    end

    ##
    # conditional setting of coordinates.
    # Returns self if coordinates were set.
    # Returns nil if new coordinates were disallowed.
    def set_coords!(x,y)
      if @map.is_within?( x, y ) and allowed_access_to?( x, y )
        super(x,y)
      else
        nil
      end
    end

    ##
    # may someone go to x,y?
    def allowed_access_to?( x, y )
      not @map.get_background(x,y).blocked? 
    end

    def allowed_access_to_relative?( dx = 0, dy = 0 )
      allowed_access_to?( @x + dx, @y + dy )
    end

    ## 
    # get the tile/object/entity from the given grid
    # at the current location on the map.
    def get(grid_type = :object)
      @map.send(grid_type).get( @x, @y )
    end

    def set(grid_type = :object, object = nil )
      @map.send(grid_type).set( @x, @y, object )
    end


    def to_maplocation
      MapLocation.new(@map,@x,@y)
    end

  end


  ## 
  # an entity on the map.
  class EntityLocation < MapLocation
    attr_reader :entity
    def initialize( entity, *args)
      @entity = entity
      super(*args)
    end

    def set_coords!(x,y)
      oldx, oldy = @x, @y
      was_moved = super(x,y)
      if was_moved
        old_entity = @map.entity.get(oldx, oldy) if oldx && oldy
        unless not old_entity or old_entity == @entity
          raise ArgumentError, "Moved entity not found on point of origin."
        end
        replaced_entity = @map.entity.get(x,y)       
        unless not replaced_entity
          raise ArgumentError, "Replaced existing entity, map corrupted."
        end
        # Remove our previous position on the map
        @map.entity.set(oldx,oldy, nil) if oldx&&oldy
        @map.entity.set( x,y, @entity )
      end
      return was_moved
    end

    def allowed_access_to?( x, y )
      super and not @map.entity.get(x,y)
    end
  end



  ##
  # a 4-way compass direction.
  class Direction
    MAX = 3
    MIN = 0
    MASK = 0x3

    # Numeric values for the directions.
    N_ID = 0
    E_ID = 1
    S_ID = 2
    W_ID = 3

    COORDINATE_VECTORS = [
      [0,-1], [1,0], [0,1], [-1,0]
    ]

    attr_reader :direction
    alias :value :direction
    def initialize( direction = 0 )
      check_direction( direction )
      self.direction=( direction )
    end
    
    def check_direction( direction )
      if direction>MAX or direction<MIN
        raise ArgumentError, "Invalid Direction."
      end
    end
    private :check_direction
    
    def sanitize!
      @direction &= MASK
    end
    
    def rotate_clockwise( step = 1)
      @direction+=step
      sanitize!
    end
    
    def rotate_counterclockwise( step = 1)
      @direction-=step
      sanitize!
    end
    
    def direction=( direction )
      direction = direction.value if direction.kind_of? Direction
      check_direction( direction )
      @direction = direction
      sanitize!
    end
    alias :value= :direction= ;
    
    def <=>(other)
      case other
      when Direction
        @direction<=>other.direction
      when Numeric
        @direction<=>other
      end
    end
    include Comparable
        
    def to_2D_vector
      COORDINATE_VECTORS[@direction]
    end

    def self.constant(dir)
      new(dir).freeze
    end

    ##
    # Constant directions.
    N = NORTH = constant(N_ID)
    E = EAST  = constant(E_ID)
    S = SOUTH = constant(S_ID)
    W = WEST  = constant(W_ID)
      
    COMPASS_DIRECTIONS = [ N, E, S, W ]
      
  end # Direction

end

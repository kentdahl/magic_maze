require 'magicmaze/tile'

module MagicMaze

  ########################################
  # A map containing objects, meant for usage during
  # the game itself.
  class GameMap
    MAP_X_SIZE = 128
    MAP_Y_SIZE = 128

    class Grid < Array
      ##
      # create a grid for one layer in the map.
      # The default tiles are:
      # inner - used to fill all empty blocks.
      # outer - returned for blocks outside the map.
      def initialize(map, tile_type = Tile, 
                     default_inner_tile = nil,
                     default_outer_tile = nil )
        @map = map
        @default_tile = default_outer_tile
        @tile_type = tile_type
        (0...MAP_Y_SIZE).each{|i|
          self.push Array.new(MAP_X_SIZE, default_inner_tile)        
        }
      end
      
      def is_within?( x, y )
        x.between?(0, @map.max_x) && y.between?(0, @map.max_y)
      end

      ##
      # return the object tile for the given coordinate. 
      def get( x, y )
        if is_within?( x, y ) then
          self[y][x]
        else
          @default_tile
        end
      end
    
      ##
      # set the entity tile for the given coordinate. 
      def set( x, y, object )
        unless !object or object.kind_of? @tile_type
          raise ArgumentError, "Expected #{@tile_type}."
        end
        if is_within?( x, y ) then
          self[y][x] = object
        else
          raise ArgumentError, "Outside map." 
        end
      end
    end

    ##
    # holds a list of active entities that 
    # need to recieve regular action_tick calls.
    class ActiveEntities 
      def initialize
        @entities = Array.new
      end
      def add_entity( entity )
        @entities << entity
      end

      def each_tick( *args )
        @entities.each{|entity|
          entity.action_tick( *args )
        }
        @entities.reject!{|entity| not entity.active? }
      end

      def remove_all
        @entities.each{|entity|
          entity.remove_entity
        }
        @entities.clear
      end

    end



    attr_reader :max_x, :max_y
    attr_reader :start_x, :start_y

    ## The layers of objects in the game.
    # background - solid walls, floor tiles
    # object - objects on the floor; keys, chests etc
    # entity - solid blocking objects; monsters, doors
    # spiritual - ephemeral objects; spells, etc.
    attr_reader :background, :object, :entity, :spiritual

    ##
    # the walkable area all in-map tiles default to.
    attr_reader :default_background_tile

    ##
    # the non-walkable tile any reference outside the map default to.
    attr_reader :default_surrounding_wall

    ##
    # active entities that may move.
    attr_reader :active_entities

    ##
    # create an empty map.
    def initialize(default_background_tile, default_surrounding_wall,
                   startx = 0, starty = 0)
      raise ArgumentError, "Expected Tile." unless 
        default_background_tile.kind_of? BackgroundTile
      raise ArgumentError, "Expected Tile." unless 
        default_surrounding_wall.kind_of? BackgroundTile

      @start_x = startx
      @start_y = starty

      @max_x = MAP_X_SIZE - 1
      @max_y = MAP_Y_SIZE - 1
      @default_background_tile = default_background_tile
      @default_surrounding_wall = default_surrounding_wall
      @background = create_grid(BackgroundTile,
                                @default_background_tile, 
                                @default_surrounding_wall )
      @object     = create_grid(ObjectTile) # inanimate objects
      @entity     = create_grid(Object)     # monsters, players, doors.
      @spiritual  = create_grid(Object)     # spells, missiles
      
      @active_entities = ActiveEntities.new
    end

    def create_grid(tile_type = Tile, 
                    default_inner_tile = nil, 
                    default_outer_tile = nil )
      Grid.new(self, tile_type, default_inner_tile, default_outer_tile)
    end
    private :create_grid

    ##
    # is the coordinate within our map area?
    def is_within?( x, y )
      x.between?(0, @max_x) && y.between?(0, @max_y)
    end

    ##
    # return the background tile for the given coordinate. 
    def get_background( x, y )
      return @background.get(x,y)
    end
    ##
    # set the background tile for the given coordinate. 
    def set_background( x, y, background )
      return @background.set(x,y,background)
    end

    ##
    # return the object tile for the given coordinate. 
    def get_object( x, y )
      return @object.get(x,y)
    end

    ##
    # set the object tile for the given coordinate. 
    def set_object( x, y, object )
      return @object.set(x,y,object)
    end


    ##
    # insert object into correct grid depending on type.
    def set_any_object( x, y, object )
      if object.kind_of? EntityTile
        entity = object.create_entity(self,x,y)
        add_active_entity( entity ) if entity.kind_of? Entity
        @entity.set( x,y, entity )
      else
        @object.set( x,y, object )
      end
    end

    ##
    # yields all tiles, from background to front.
    def each_tile_at( x, y )
      yield @background.get(x,y)
      yield @object.get(x,y)
      yield @entity.get(x,y)
      yield @spiritual.get(x,y)
    end

    def all_tiles_at( x, y )
      yield @background.get(x,y), @object.get(x,y),  @entity.get(x,y), @spiritual.get(x,y)
    end

    ##
    # add an Entity that needs to have its action_tick called
    # during the game loop.
    def add_active_entity( entity )
      @active_entities.add_entity( entity )
    end
    # protected :add_active_entity


    def purge
      @active_entities.remove_all
    end

    
    def iterate_all_cells( offset = 0, &block )
      (0-offset...MAP_Y_SIZE+offset).each do |y|
	(0-offset...MAP_X_SIZE+offset).each do |x|
	  all_tiles_at( x, y ) do |b,o,e,s|
	    yield x, y, b, o, e, s
	  end
	end
      end
    end

    def iterate_all_rows( offset = 0, &block )
      (0-offset...MAP_Y_SIZE+offset).each do |y|
        yield y, offset
      end
    end

    def iterate_all_columns( offset = 0, &block )
      (0-offset...MAP_X_SIZE+offset).each do |x|
        yield x, offset
      end
    end



  end

end 


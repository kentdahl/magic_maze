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

require 'magicmaze/map'

module MagicMaze
  ## 
  # Old style filemap.
  # Basically just loads in the binary data as 8-byte strings.
  class FileMap 
    MAP_HEADER_SIZE = 256
    MAP_SIZE = 32768
    MAP_FILE_SIGNATURE = 'MagicMazeMap'
    MAP_ROW_SIZE = 256
    MONSTER_NUMBER_BEGIN = 40
    MONSTER_NUMBER_END   = MONSTER_NUMBER_BEGIN + 20 - 1
    EMPTY_ROW = []

    TILE_BITS   = 127
    BLOCKED_BIT = 128

    attr_reader :startx, :starty, :title
    attr_reader :checksum, :default_wall_tile, :map_rows

    ##
    # Open an old-style filemap for Magic Maze.
    # Filename must point to a valid map file.
    def initialize( filename, monster_maker = nil )
      @file = File.open(filename, 'rb')
      @header_data = @file.read(MAP_HEADER_SIZE)
      unless MAP_FILE_SIGNATURE == @header_data[0,MAP_FILE_SIGNATURE.size]
	raise ArgumentError, "Map file is invalid: "+filename
      end
      
      extract_from_header( @header_data )
    end

    def load_map
      @real_checksum = 0
      @map_rows = []
      begin
	row = @file.read(MAP_ROW_SIZE)
	extract_from_row( row ) if row
	yield row if block_given?
      end while row     
      @real_checksum &= 0xFFFF
      unless @checksum == @real_checksum 
	raise ArgumentError, "Map file checksum failed: "+
	  "Excpected #@checksum, found #@real_checksum."
      end
    end

    def close
      @file.close if @file
      @file = nil
    end

    if defined?(RUBY_PLATFORM) # Ruby 1.9
      def convert_string_to_bytes( str )
        str.bytes.collect{|i| i } # Ruby 1.9
      end
    else
      def convert_string_to_bytes( str )
        str # Ruby 1.8
      end
    end
    
    ##
    # Extract various data from the header part of the map.
    def extract_from_header( header_data_str )
      header_data = convert_string_to_bytes( header_data_str )
      @checksum = header_data[16] + (header_data[17]<<8)
      @startx =   header_data[24]
      @starty =   header_data[25]
      @default_wall_tile = header_data[30]
      @last_level = header_data[32] & BLOCKED_BIT == BLOCKED_BIT

      @title = ""
      index = 128        
      begin
        char = header_data[index]
        char = nil if char<32 or index>166
        @title << char if char
        index += 1
      end while char 
      @title.chop
    end
    private :extract_from_header

    ##
    # Extract map structure from rows.
    def extract_from_row( row_data )
      # calculate checksum
      row_data.each_byte{|byte|
        @real_checksum += byte
      }
      # what if the row is less than 256 bytes? Pad it.
      pad_row( row_data )
      # store the raw data
      @map_rows << row_data
    end
    private :extract_from_row

    def pad_row( row_data )
      # what if the row is less than 256 bytes? Pad it.
      unless row_data.size >= MAP_ROW_SIZE
        row_data << "\000"*(MAP_ROW_SIZE-row_data.size)
      end     
    end

    ##
    # remove monsters from the map data and add them to the live
    # monster list.
    def extract_monsters( monster_maker )
      each_row{|row, y|  # @map_rows.each_with_index{|row,y|
        each_column{|x|  # (0...MAP_ROW_SIZE/2).each{|x|
          object = row[x*2+1]
          puts "#{x}, #{y}" unless object
          if object >= MONSTER_NUMBER_BEGIN and object <= MONSTER_NUMBER_END
            monster_maker.add_monster( object, x, y )
            row[x*2+1]=0
          end
        }
      }
    end

    # Iterate over every row (or y value)
    def each_row( &block )
      @map_rows.each_with_index{|row,y| yield row, y }
    end

    def each_column( &block )
      (0...MAP_ROW_SIZE/2).each{|x| yield x }
    end

    ##
    # return background code for the position given.
    # If the most significant bit is set, it is blocked.
    # If the coordinate is outside the map, a default block is returned.
    def get_background_data( x, y )
      row = convert_string_to_bytes(@map_rows[y])
      row ||= EMPTY_ROW
      index = x*2
      if (index<0||index>=row.size) then
        @default_wall_tile 
      else
        row[index]
      end
    end

    ##
    # return background tile, without the blocked bit.
    def get_background_tile( x, y )
      get_background_data( x, y ) & TILE_BITS
    end
    
    def set_background_tile( x, y, background, blocked = false)
      row = @map_rows[y]
      row[x*2] = background
    end
    

    ##
    # return object code for the position given.
    def get_object( x, y )
      row = convert_string_to_bytes(@map_rows[y])
      object = row[x*2+1]
    end
    alias :get_object_data :get_object

    ##
    # place an object.
    def set_object( x, y, object )
      @map_rows[y][x*2+1] = object
    end

    ##
    # is that position blocked?
    def is_blocked?( x, y )
      get_background_data( x, y ) & BLOCKED_BIT == BLOCKED_BIT
    end


    def to_gamemap
      load_map if @map_rows.nil? and @file
      close # close file, no more reading.
      @tilehash = {
        :object=>DEFAULT_TILES_ID_LOOKUP.dup,
        :background=>{}
      }
      wall_id = @default_wall_tile
      wall_id = 10 if wall_id==0
      background_tile = BackgroundTile.new(0, false)
      wall_tile       = BackgroundTile.new(wall_id, true)
      @tilehash[:background][0] = background_tile
      @tilehash[:background][wall_id|BLOCKED_BIT] = wall_tile


      gamemap = GameMap.new(background_tile, wall_tile,
                            startx, starty)
      each_row{|row, y|  
        each_column{|x|  
          # background tiles.
          tile_id =  self.get_background_data( x, y )

	  # Change the plain empty background tile occasionally. Helps with large open spaces.
	  if tile_id == 0 and x&2==2 and y&2==2 then
	    tile_id = 1
	  end
	  
	  tile_number = tile_id&TILE_BITS
	  tile_blocked = tile_id&BLOCKED_BIT==BLOCKED_BIT
	  
          tile = fetch_or_create_tile( tile_id, :background ) {|tile_id| 
            BackgroundTile.new( tile_number, tile_blocked )
          }

	  # Just for testing...
	  if tile.blocked? and !tile_blocked
	    puts "ERROR with tile at #{x}, #{y}" 
	    p @tilehash[:background][10]
	    p @tilehash[:background][138]
	    p tile
	  end

          gamemap.set_background( x, y, tile )
          # object tiles
          tile_id = self.get_object_data( x, y )
          tile = fetch_or_create_tile( tile_id, :object ) {|tile_id| 
            ObjectTile.new( tile_id )
          }
          gamemap.set_any_object( x, y, tile ) if tile_id>0 
        }
      }
      gamemap
    end # to_gamemap

    
    ##
    # tries to fetch similar tile from the tilehash, 
    # constructs new using block if not.
    def fetch_or_create_tile( tile_id, hashtype)
      tilehash = @tilehash[hashtype]
      tile = tilehash[ tile_id ]
      unless tile
        tile = yield tile_id
        tilehash[tile_id] = tile
      end
      tile
    end
    
    
    ##
    # Update map from GameMap.
    def from_gamemap(gamemap)
      # @map_rows = []
      gamemap.iterate_all_rows do |y, oy|
        @map_rows[y]  ||= ""
        pad_row(@map_rows[y])
        gamemap.iterate_all_columns do |x, ox|
          gamemap.all_tiles_at(x,y){|back, object, entity, spiritual|
            set_background_tile(x,y, back.sprite_id, back.blocked?)
            set_object(x,y,object.sprite_id) if object
          }
        end
      end
    end
    
    def update_header_data
      @header_data[24] = @startx   
      @header_data[25] = @starty   
    end
    
    def save_to(filename)
      close
      @file = File.open(filename, 'wb')
      @file.write @header_data
      each_row {|row, y|
        @file.write row
      }
      @file.close
    end

  end # FileMap
end

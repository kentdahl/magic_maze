require 'magicmaze/filemap'
require 'json'


class MapExporter

  attr_reader :gamemap, :filemap  ##< Current map being processed.

  def initialize(filemap)
    @filemap = filemap
    @gamemap = filemap.to_gamemap
  end


  MAP_X_SIZE = ::MagicMaze::GameMap::MAP_X_SIZE
  MAP_Y_SIZE = ::MagicMaze::GameMap::MAP_Y_SIZE


  # https://github.com/bjorn/tiled/wiki/JSON-Map-Format
  def to_tiled_json
    @gamemap ||= filemap.to_gamemap

    {
      width:  MAP_X_SIZE,
      height: MAP_Y_SIZE,
      tilewidth: 32,
      tileheight: 32,
      orientation: 'orthogonal',  
      
      layers: [
        # The Background layer  # FIXME: What about invisible walls and hidden passages?
        {
          width:  MAP_X_SIZE,
          height: MAP_Y_SIZE,
          name: "Background",
          opacity: 1.0,
          type: "tilelayer",
          visible: true,
          x: 0,
          y: 0,
          properties: {},
          data:  background_layer_to_data
        },
        # TODO: Foreground layer separate?
        # Objects layer
        {
          width:  MAP_X_SIZE,
          height: MAP_Y_SIZE,
          name: "Objects",
          opacity: 1.0,
          type: "objectgroup",
          visible: true,
          x: 0,
          y: 0,
          properties: {},
          objects: object_layer_to_data,
          draworder: "topdown",
        },
        # Entities layer
        {
          width:  MAP_X_SIZE,
          height: MAP_Y_SIZE,
          name: "Entities",
          opacity: 1.0,
          type: "objectgroup",
          visible: true,
          x: 0,
          y: 0,
          objects: entity_layer_to_data,
          draworder: "topdown",
        },

      ],
      tilesets: [
        {
          firstgid: 1,  # NOTE: Tiled editor won't open if this is 0....
          image: "../../../data/gfx/sprites.png",
          imageheight: 288,
          imagewidth: 320,
          margin: 0,
          name: "sprites",
          properties:
            {
            },
          spacing: 0,
          tileheight: 32,
          tilewidth: 32,
          transparentcolor: "#000000"
        },

      ],
      backgroundcolor: "#222222", # string  Hex-formatted color (#RRGGBB) (Optional)
      # renderorder: "",  # string  Rendering direction (orthogonal maps only)
      properties: {
        start_x: gamemap.start_x,
        start_y: gamemap.start_y,
        title: filemap.title
      },
      nextobjectid: 1,  #  int Auto-increments for each placed object
      renderorder: "right-down",
      version: 1
    }
  end


  def background_layer_to_data
    data = []
    (0..gamemap.max_y).each do   |y|
      (0..gamemap.max_x).each do |x|
        tile =  gamemap.background.get( x, y )
        data << (tile && tile.sprite_id.to_i + 1) || 0
      end
    end
    unless data.size == 128*128
      raise "Data size inconsistent! #{ data.size } "
    end
    data
  end

  def object_layer_to_data
    list = []
    filemap.each_row do |row, y|  
      filemap.each_column do |x|
        obj =  gamemap.object.get( x, y )
        next unless obj
        data = 
            {
              gid: obj.sprite_id + 1, # FIXME: + ::MagicMaze::FileMap::MONSTER_NUMBER_BEGIN,
              x: x * 32,
              y: y * 32,
              height: 32, width: 32,
              type: obj.class.to_s.split(":").last,
              visible: true,
              properties: {
              },
            }
        list << data
      end
    end
    list
  end


  def entity_layer_to_data
    gamemap.active_entities.all.collect do |entity|
      {
        gid: entity.sprite_id + 1, # FIXME: + ::MagicMaze::FileMap::MONSTER_NUMBER_BEGIN,
        x: entity.location.x * 32,
        y: entity.location.y * 32,
        height: 32, width: 32,
        type: "Monster", # TODO: Any others here? # WAS: entity.class.to_s,
        visible: true,
        properties: {
        },
      }
    end
  end




  module ClassMethods
    # Iterate all default maps.
    def for_all_default_maps(upto=10)
      for_all_default_map_filenames(upto) {|filename|
        @filemap = MagicMaze::FileMap.new( filename )
        yield @filemap
        @filemap = nil
      }
    end

    ##
    # Iterate all default maps filenames.
    def for_all_default_map_filenames(upto=10)
      (1..upto).each do|level|
        @filename = sprintf "data/maps/mm_map.%03d", level
        yield @filename
        @filename = nil
      end
    end

    def perform
      output_dir = "data/maps/tiled/"
      map_count = 0

      for_all_default_maps do |map|
        map_count +=1 
        @filemap = map

        filename = output_dir + sprintf("mm_map%03d.json", map_count)

        tiled_map = self.new(map).to_tiled_json

        File.open(filename, 'w') do |output|
          puts "#{filename} ..."
          json_str = tiled_map.to_json
          # json_str = JSON.pretty_generate(tiled_map) # For debugging.
          output.puts json_str
        end
        @filemap = nil

      end
    end

  end # ClassMethods
  extend ClassMethods

end


MapExporter.perform

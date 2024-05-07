require 'test/unit'

require 'magicmaze/filemap'

require 'tempfile'

class TestFileMap < Test::Unit::TestCase
  def setup
  end

  ##
  # Test that all maps can be loaded OK.
  def test_loading_filemaps
    for_all_default_maps do |filemap|
      filemap.load_map
      gamemap = filemap.to_gamemap
      filemap.close
      assert( gamemap )
      assert( filemap.title.size.nonzero? )
      print_progress
    end
  end
  
  ##
  # Test loading and saving filemaps.
  def test_saving_filemaps
    for_all_default_maps do |filemap|
      filemap.load_map  
      filemap.close
      
      # Save a copy to separate file.
      newfilename = temp_map_filename
      filemap.save_to( newfilename)
      
      # Load back in from the temporary file and compare.
      newfilemap = MagicMaze::FileMap.new( newfilename )
      assert_equal( filemap.title, newfilemap.title )
      assert_equal( filemap.startx, newfilemap.startx )
      assert_equal( filemap.starty, newfilemap.starty )
      assert_equal( filemap.checksum, newfilemap.checksum )
      
      newfilemap.load_map
      assert( newfilemap.map_rows )
      assert_equal( filemap.map_rows.size, newfilemap.map_rows.size )
      filemap.each_row {|row, y|
        assert_equal( row, newfilemap.map_rows[y] )
      }
      # assert_equal( filemap., newfilemap. )
      
      print_progress
      
    end
  end
  
  def test_modified_maps
    for_all_default_maps(3) do |filemap|
      filemap.load_map
      filemap.close
      
      # Modify
      newfilename = temp_map_filename
      filemap.instance_eval { @startx = 12 }
      filemap.instance_eval { @starty = 34 }
      gamemap = filemap.to_gamemap
      filemap.from_gamemap(gamemap)
      filemap.update_header_data
      filemap.save_to( newfilename )
      
      # Load back in from the temporary file and compare.
      newfilemap = MagicMaze::FileMap.new( newfilename )
      assert_equal( filemap.title, newfilemap.title )
      assert_equal( filemap.startx, newfilemap.startx )
      assert_equal( filemap.starty, newfilemap.starty )
      assert_equal( 12, newfilemap.startx )
      assert_equal( 34, newfilemap.starty )
    end
  end
  
  ##
  # Iterate all default maps filenames.
  def for_all_default_map_filenames(upto=10)
    (1..upto).each do|level|
      @filename = sprintf MAP_PATH+"mm_map.%03d", level
      yield @filename
    end
  end
  
  ##
  # Iterate all default maps.
  def for_all_default_maps(upto=10)
    for_all_default_map_filenames(upto) {|filename|
      @filemap = MagicMaze::FileMap.new( filename )
      assert( @filemap )
      yield @filemap
    }
  end
  
  ##
  # Create a temporary filename based on the currently loaded map.
  def temp_map_filename
    # Save a copy to separate file.
    tmp = Tempfile.new(File.basename(@filename))
    newfilename = tmp.path
    tmp.close
    return newfilename
  end

  
  def print_progress 
    print "."; STDOUT.flush
  end
    
end

require 'test/unit'

require 'magicmaze/filemap'

require 'tempfile'

class TestFileMap < Test::Unit::TestCase
  def setup
  end

  def test_loading_filemaps
    (1..10).each do|level|
      filename = sprintf "data/maps/mm_map.%03d", level
      filemap = MagicMaze::FileMap.new( filename )
      filemap.load_map
      assert( filemap )
      gamemap = filemap.to_gamemap
      filemap.close
      assert( gamemap )
      assert( filemap.title.size.nonzero? )
      print "."; STDOUT.flush
    end
  end
  
  def test_saving_filemaps
    (1..10).each do|level|
      filename = sprintf "data/maps/mm_map.%03d", level
      filemap = MagicMaze::FileMap.new( filename )
      filemap.load_map
      assert( filemap )
      filemap.close
      
      # Save a copy to separate file.
      tmp = Tempfile.new(File.basename(filename))
      newfilename = tmp.path
      tmp.close
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
      
      print "."; STDOUT.flush
      
    end    
  end
end

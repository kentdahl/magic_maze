require 'test/unit'

require 'magicmaze/filemap'

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
      print "."
    end
  end
end

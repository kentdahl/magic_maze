require 'test/unit'

require 'magicmaze/filemap'

class TestFileMap < Test::Unit::TestCase
  def setup
  end

  def test_loading_filemaps
    (1..10).each do|level|
      filename = sprintf "data/maps/mm_map.%03d", level
      filemap = MagicMaze::FileMap.new( filename )
      assert( filemap )
      gamemap = filemap.to_gamemap
      assert( gamemap )
      assert( filemap.title.size.nonzero? )
    end
  end
end

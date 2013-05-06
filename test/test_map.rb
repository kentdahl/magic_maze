require 'test/unit'

require 'magicmaze/map'
require 'magicmaze/tile'

class TestMagicGameMap < Test::Unit::TestCase
  class TestTile < MagicMaze::BackgroundTile; end
  def setup
    @tile = TestTile.new
    @wall = TestTile.new
    @map = MagicMaze::GameMap.new( @tile, @wall )
  end
  def test_tile
    assert_raises(ArgumentError, "Expected Tile."){
      MagicMaze::GameMap.new( nil, nil )
    }
    assert_raises(ArgumentError, "Expected Tile."){
      MagicMaze::GameMap.new( @tile, nil )
    }
    assert_raises(ArgumentError, "Expected Tile."){
      MagicMaze::GameMap.new( nil, @wall )
    }
  end
  def test_access
    max_x = MagicMaze::GameMap::MAP_X_SIZE-1
    max_y = MagicMaze::GameMap::MAP_Y_SIZE-1
    tests = [
      [true, 5,5],
      [true, 0,5],
      [true, 0,0],
      [true, max_x,0],
      [true, 0,max_y],
      [false, max_x+1,0],
      [false, 0,max_y+1],
      [false, max_x+1, max_y+1],
    ]
    tests.each{|expected, x, y|
      assert_equal( expected, @map.is_within?( x, y ), "(#{x}, #{y})" )
    }
  end
end

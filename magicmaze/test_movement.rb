require 'magicmaze/movement'

require 'test/unit'


class TestDirection < Test::Unit::TestCase
  Direction = MagicMaze::Direction

  def setup
    @dir = Direction.new
  end

  def test_constructor    
    (Direction::MIN..Direction::MAX).each{|i|
      assert_equal( i, Direction.new( i ).direction )
    }
    [ Direction::MIN-2, Direction::MIN-1, 
      Direction::MAX+1, Direction::MAX+2 
    ].each{|i|
      assert_raises( ArgumentError ){
        Direction::new( i )
      }
    }
  end

  def test_rotate
    dirs = [
      Direction::EAST, 
      Direction::SOUTH, 
      Direction::WEST, 
      Direction::NORTH,
    ] * 4
    dirs.each{|i|
      @dir.rotate_clockwise
      assert_equal( i, @dir )
    }
  end

  def test_rotate_counter
    dirs = [
      Direction::WEST, 
      Direction::SOUTH, 
      Direction::EAST, 
      Direction::NORTH,
    ] * 4
    dirs.each{|i|
      @dir.rotate_counterclockwise
      assert_equal( i, @dir )
    }
  end


end

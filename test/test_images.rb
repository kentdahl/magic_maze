require 'test/unit'

require 'magicmaze/magicmaze'
require 'magicmaze/images'


class TestGraphicsImages < Test::Unit::TestCase
  include MagicMaze::Images

  alias :old_sleep_delay :sleep_delay
  def sleep_delay(sleep_ms=0)
    # speed tests up.
    @last_sleep_delay = sleep_ms
  end

  def set_palette( pal, start_color = 0 )
    @last_set_palette = pal
  end

  def setup
    @sprite_palette = [
      [5,5,5], [5,0,0], [0,5,0], [0,0,5]
    ]
  end


  def todo_test_fade_in
    @sprite_palette = [
      [5,5,5], [5,0,0], [0,5,0], [0,0,5]
    ]
    expected_palette = (0...5).collect{|j|
      i = j.to_f
      [ [i,i,i], [i,0,0], [0,i,0], [0,0,i] ]
    }
    fade_in(5){|i,range|
      assert_equal( 4, range )
      assert_equal( expected_palette.shift, @last_set_palette )
    }
  end

  def todo_test_fade_out
    @sprite_palette = [
      [25,25,25], [25,0,0], [0,25,0], [0,0,25]
    ]
    expected_palette = (0..25).collect{|i|
      [ [i,i,i], [i,0,0], [0,i,0], [0,0,i] ]
    }
    fade_out(5,5,5, 21){|i,range|
      assert_equal( 21, range )
      assert_equal( expected_palette.pop, @last_set_palette )
    }
  end



  def test_fade_in_and_out
    @last_sleep_delay = 0
    count = 0
    self.fade_in_and_out(25){
      count += 1
    }
    assert( count > 0 )
    assert_equal( 25, @last_sleep_delay )

  end

  def test_delay
    self.old_sleep_delay
  end
    

end

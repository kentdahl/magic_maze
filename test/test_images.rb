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


  def todo_test_fade_in_and_out
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

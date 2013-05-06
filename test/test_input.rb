require 'test/unit'

require 'magicmaze/game'

class TestInputControl < Test::Unit::TestCase


  def setup
    @title_input = MagicMaze::Input::Control.new( self, :titlescreen )
  end

  def test_callback
    @title_input.call_callback(:open_game_menu)
    assert_equal( 1, @mock)
  end

  def todo_test
  end

  def inc_mock_counter
    @mock ||= 0
    @mock += 1
  end
  
  alias :open_game_menu :inc_mock_counter

end

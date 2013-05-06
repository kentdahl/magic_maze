require 'test/unit'

require 'magicmaze/magicmaze'
require 'magicmaze/sound'


class TestSound < Test::Unit::TestCase

  def setup
    @s = MagicMaze::Sound.get_sound
  end

  def test_initialize
    assert_not_nil( @s.instance_eval{ @sounds  } )
    assert_equal(4, @s.instance_eval{ @sounds.size } )
  end

end


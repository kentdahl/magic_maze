require 'test/unit'

require 'magicmaze/magicmaze'
require 'magicmaze/graphics'


class TestGraphics < Test::Unit::TestCase

  def setup
    @g = MagicMaze::Graphics.get_graphics
  end

  def teardown
    # MagicMaze::Graphics.shutdown_graphics
  end

  def test_initialize
    assert_not_nil( @g.instance_eval{ @screen } )
    assert_not_nil( @g.instance_eval{ @sprite_images } )
  end

  def test_font_init
    assert_not_nil( @g.instance_eval{ @font } )
    assert_not_nil( @g.instance_eval{ @font16 } )
    assert_not_nil( @g.instance_eval{ @font32 } )
  end

  def test_load_background_images
    assert_equal( 3, @g.instance_eval{ @background_images.size } )
  end

  def test_load_new_sprites
    assert_not_nil( @g.instance_eval{ @sprite_palette } )
    assert_not_nil( @g.instance_eval{ @sprite_images  } )
    assert_equal( 90, @g.instance_eval{ @sprite_images.size } )
  end

end

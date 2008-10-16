require 'test/unit'

require 'magicmaze/magicmaze'
require 'magicmaze/graphics'


class TestGraphics < Test::Unit::TestCase

  def setup
    @g = MagicMaze::Graphics.get_graphics
    def @g.sleep_delay(sleep_ms=0)
      # speed tests up.
    end
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

  def test_write_score
    @g.write_score(0)
    @g.write_score(9999999)
    @g.write_score(-9999999.99999)
  end

  def test_show_message
    @g.show_message("Test")
    @g.show_message("Testing the message box", false)
    @g.show_message("Testing the message box... \n" * 5)
  end

  def test_show_long_message
    @g.show_long_message("Test long")
    @g.show_long_message("Testing the LONG message box", false)
    @g.show_long_message("Testing the LONG message box... \n" * 5)
    @g.show_long_message("Testing the LONG message box", true, true)
    @g.show_long_message("Testing the LONG message box!!! \n" * 20, true, true)
  end

  def test_update_life_and_mana
    @g.update_life_and_mana(0,0)
    @g.update_life_and_mana(50,0)
    @g.update_life_and_mana(100,50)
    @g.update_life_and_mana(100,100)
  end

  def test_update_inventory
    @g.update_inventory( [] )
    @g.update_inventory( [1] )
    @g.update_inventory( [1,2,3,4,5] )
  end

  def test_update_spells
    # @g.update_spells(nil,nil)
    @g.update_spells(1,2)
    @g.update_spells(3,5)
  end


  ####################################

  def test_show_help
    @g.show_help
  end

  def todo_test_draw_map
    player = 
    @g.draw_map(player)
  end

  def test_scrolltext
    @g.prepare_scrolltext("This is a" + "long, " * 50 + " long text string... ")
    500.times { @g.update_scrolltext; }
  end
  

  def test_rotating_palette
    @g.setup_rotating_palette(1..255)
    50.times { @g.rotate_palette }
  end

  def test_setup_menu
    @g.setup_menu( %w{OK Cancel} )
    assert_not_nil( @g.instance_eval { @menu_items } )
    assert( ! @g.instance_eval { @menu_truncate_size } )

    @g.setup_menu( %w{Yes No OK Cancel}, "OK" )
    assert_equal( "OK", @g.instance_eval { @menu_chosen_item} )

    @g.setup_menu( ("Repeat... "*50).split )
    assert( @g.instance_eval { @menu_truncate_size } )
  end

  def test_draw_menu
    @g.setup_menu( (1..5).collect{|i| "Choice #{i}"} )
    10.times { 
      @g.draw_menu
      @g.next_menu_item
    }
  end

  def test_next_menu_item
    @g.setup_menu( (0...50).collect{|i| "Choice #{i}"} )
    50.times {|i| 
      assert_equal( "Choice #{i}", @g.menu_chosen_item )
      @g.next_menu_item
    }
    50.times {|i| 
      assert_equal( "Choice #{i}", @g.menu_chosen_item )
      @g.next_menu_item
    }
  end

end

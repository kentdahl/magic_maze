require 'test/unit'

require 'magicmaze/game'

class TestMagicMazeGame < Test::Unit::TestCase

  class Dummy
    attr_reader :options
    def initialize(options)
      @options = options
    end
  end

  class DummyGraphics < Dummy ; end
  class DummySound    < Dummy ; end

  class MagicMazeGame < MagicMaze::Game
    def init_graphics
      @graphics = DummyGraphics.new( @options )
    end
  end


  def setup
    @default_options = { 
      :sound=>true,
    }
    @game = MagicMazeGame.new( @default_options )
  end

  def test_initialize
    assert_not_nil( @game.graphics )
    assert_not_nil( @game.sound )
    assert_equal( MagicMaze::SDLSound, @game.sound.class )
  end

  def disabled_test_initialize_sound
    game = MagicMazeGame.new({:sound=>false})
    assert_equal( MagicMaze::NoSound, game.sound.class )
    game = MagicMazeGame.new({:sound=>true})
    assert_equal( MagicMaze::SDLSound, game.sound.class )
    game = MagicMazeGame.new(Hash.new)
    assert_equal( MagicMaze::NoSound, game.sound.class )
  end

end

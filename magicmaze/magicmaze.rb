require 'magicmaze/gameloop'

require 'magicmaze/graphics'
require 'magicmaze/input'
require 'magicmaze/sound'

# necessary for pthreads/sound problem?
require 'rbconfig'
if RUBY_PLATFORM =~ /linux/
  trap('INT','EXIT')
#  trap('EXIT','EXIT')
end

################################################
#
module MagicMaze

  ################################################
  #
  class Game

    attr_reader :graphics, :sound
    def initialize
      @graphics = Graphics.new
      @sound = Sound.new
      @title_input = Input::Control.new( self, :titlescreen )    
      @quit = false
    end
    

    def exit
      Kernel.exit
    end
    def escape
      puts "Escape"
      @state = :stopped_game
    end
    def exit_game
      puts "Exit game"
      @quit = true
      @state = :exiting_game
    end

    def toogle_fullscreen
      @graphics.toogle_fullscreen
    end

    def test_1
      @sound.play_sound( :argh )
    end
    def test_2
      @sound.play_sound( :zap  )
    end
    def test_3
      @sound.play_sound( :punch )
    end
    def test_4
      @sound.play_sound( :bonus )
    end


    def title_loop
      puts "Title loop..."
      @graphics.put_screen( :titlescreen, true )
      @state = :title_loop
      while @state == :title_loop
        @title_input.check_input
      end
    end

    def loop
      puts "Starting..."
      while not @quit
        title_loop
      end
      puts "Exiting..."
    end

    def start_game
      @state = :starting_game
      @current_game = GameLoop.new( self )
      @current_game.start
      @state = :stopped_game
    end

      
  end
  
end



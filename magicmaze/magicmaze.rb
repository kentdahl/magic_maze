require 'magicmaze/gameloop'

require 'magicmaze/graphics'
require 'magicmaze/input'
require 'magicmaze/sound'

require 'yaml'

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
    def initialize( options )
      @options = options
      @graphics = Graphics.new
      @sound = if @options[:sound] then SDLSound.new else NoSound.new end
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

    def test_fade
      puts "hullo"
      @graphics.fade_out do 
	@graphics.put_screen( :titlescreen, true )
      end
      @graphics.fade_in do 
	put_titlescreen
      end
    end
    
    def test_helpscreen
      @graphics.show_help
      @title_input.get_key_press
      put_titlescreen
    end
    
    def put_titlescreen
      @graphics.put_screen( :titlescreen, true )
    end
    
    
    def title_loop
      puts "Title loop..."
      @graphics.fade_in do 
	put_titlescreen
	SDL.delay(1)
      end
      @state = :title_loop
      while @state == :title_loop
        @title_input.check_input
      end
    end

    def loop
      puts "Starting..."
      load_checkpoints
      while not @quit
        title_loop
      end
      save_checkpoints
      puts "Exiting..."
    end

    def start_game
      @graphics.fade_out do 
	@graphics.put_screen( :titlescreen, true )
      end
      @state = :starting_game
      @current_game = GameLoop.new( self, @options[ :start_level] || 1 )
      @current_game.start
      @state = :stopped_game
    end



    ##
    # Update the player checkpoint status for this level
    # if the score is higher than previous value.
    #
    def update_checkpoint( level, status )
      checkpoint = @saved_checkpoints[ level ]
      if (not checkpoint) || (checkpoint[:score] <= status[:score])
	puts "Updating checkpoint for level #{level}."
	@saved_checkpoints[ level ] = status
      end      
    end


    def load_checkpoints
      checkpoints = Hash.new 
      begin
	File.open('data/progress.dat','r') do|file|
	  obj = YAML.load( file )	  
	  checkpoints = obj if obj.kind_of? Hash 
	end
      rescue Exception => e
	puts "Error reading checkpoints: " + e.inspect	
      end      
      @saved_checkpoints = checkpoints
    end

    def save_checkpoints
      begin
	File.open('data/progress.dat','w') do|file|
	  puts "Saving checkpoints..."
	  file.puts @saved_checkpoints.to_yaml
	end
      rescue Exception => e
	puts "Error saving checkpoints: " + e.inspect	
      end            
    end


      
  end

  
end



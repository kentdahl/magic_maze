############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2008 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'magicmaze/gameloop'
require 'magicmaze/graphics'
require 'magicmaze/input'
require 'magicmaze/sound'

require 'yaml'

################################################
#
module MagicMaze

  ################################################
  #
  class Game

    NUM_LEVELS = 10

    attr_reader :graphics, :sound
    def initialize( options )
      @options = options
      init_graphics
      init_sound
      init_input

      savedir = (@options[:savedir] ||
		 (ENV.include?("HOME") ? 
		  (ENV['HOME'] + '/.magicmaze') : nil) || "data" )

      @savegame_filename = savedir + "/progress.dat"
      @loadgame = (options[:loadgame] || false)
      @quit = false

    end

    def init_graphics
      @graphics = Graphics.get_graphics( @options )
    end

    def init_sound
      @sound = if @options[:sound]
               then 
		 begin
		   Sound.get_sound(@options) 
		 rescue SDL::Error => sound_error
		   puts "ERROR: Could not initialize sound! Proceeding muted." 
		   NoSound.new
		 end
               else 
		 NoSound.new 
               end
    end

    def init_input
      if @options[:joystick] then Input::Control.init_joystick( @options[:joystick] ) end

      @title_input = Input::Control.new( self, :titlescreen )
    end


    def destroy
      @graphics = MagicMaze::Graphics.shutdown_graphics
    end

    def exit
      destroy
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

    def test_fade
      # THIS IS FOR TESTING!
      @graphics.fade_out {}
      @graphics.put_screen( :titlescreen, true )

      @graphics.fade_out do 
        @graphics.sleep_delay(1)
      end
      put_titlescreen
      
      @graphics.fade_in do 
        @graphics.sleep_delay(1)
      end
    end
    
    def test_endgame
      show_end_game
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
      @graphics.fade_out {}
      put_titlescreen
      @graphics.fade_in do 
	@graphics.sleep_delay(1)
      end
      @state = :title_loop
      while @state == :title_loop
        @title_input.check_input
      end
      @graphics.fade_out { @graphics.sleep_delay(1)}
      @graphics.clear_screen
      @graphics.fade_in {}
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

    def start_game( level = nil, player_status = nil )
      pregame_preparation
      start_level = level || @options[:start_level] || 1
      if @loadgame && ! @saved_checkpoints.empty? then
        start_level, player_status = @saved_checkpoints.max
      end

      @current_game = GameLoop.new( self, start_level, player_status )
      @current_game.start
      show_end_game if @state == :endgame
      @state = :stopped_game
    end

    def start_training_game( start_level = 1 )
      pregame_preparation
      @current_game = GameLoop.new( self, start_level, :training )
      @current_game.start
      @state = :stopped_game
    end

    def start_replay_level_game( start_level = 1 )
      pregame_preparation
      player_status = @saved_checkpoints[ start_level ]
      @current_game = GameLoop.new( self, start_level, player_status )
      @current_game.start
      @state = :stopped_game
    end

    # The fade before starting the game.
    def pregame_preparation
      @graphics.put_screen( :titlescreen, true )
      @graphics.fade_out{ @graphics.sleep_delay(1) }
      @state = :starting_game
    end


    def open_game_menu
      menu_items = [
	"Start new game",
	"Training",
      ]
      if not @saved_checkpoints.empty? then
	menu_items.unshift("Continue game") 
	menu_items.push("Replay level") if @saved_checkpoints.size>1
      end
      menu_items.push "Quit Magic Maze"

      case choose_from_menu( menu_items )
      when /Continue/, /Load/
	select_game_checkpoint
      when /New/, /Start/
	start_game
      when /Exit/, /Quit/
	exit_game
      when /Training/
	open_training_menu
      when /Replay/
	open_replay_menu
      end
    end

    def open_training_menu
      menu_items = (1..NUM_LEVELS).collect{|i| "Level #{i}" }
      menu_items.push "Back"

      case choose_from_menu( menu_items )
      when /(\d+)/
	start_training_game( $1.to_i )
      when /Back/, /Exit/
	# Just fall out of the loop
      end
      put_titlescreen
    end

    def open_replay_menu
      menu_items = @saved_checkpoints.keys.sort.collect{
	|i,j| 
	"Replay level #{i}" 
      }
      menu_items.push "Back"

      case choose_from_menu( menu_items )
      when /(\d+)/
	start_replay_level_game( $1.to_i )
      when /Back/, /Exit/
	# Just fall out of the loop
      end
      put_titlescreen
    end


    ##
    # This does a generic menu event loop
    #
    def choose_from_menu( menu_items = %w{OK Cancel} )
      @graphics.setup_menu(menu_items)
      begin
	@graphics.draw_menu
	menu_event = @title_input.get_menu_item_navigation_event
	if [:previous_menu_item, :next_menu_item].include?(menu_event) then
	  @graphics.send(menu_event)
	end
      end until [:exit_menu, :select_menu_item].include?(menu_event)
      @graphics.erase_menu
      if menu_event == :select_menu_item then
	return @graphics.menu_chosen_item
      else
	return false
      end
    end



    END_GAME_TEXT =       
      "LuciPer escapes into the dimension " +
      "bettter known as...." +
      " HELL ...    " +
      "The world is once again safe...   " + 
      " FOR NOW!   " + 
      "Thank you for playing Magic Maze. " + 
      "Hope you enjoyed it!    " +
      "   ..Good Bye..     " + 
      ""
    

    def show_end_game
      @graphics.setup_rotating_palette( 193..255, :endscreen )

      @graphics.put_screen( :endscreen)
      @graphics.fade_in do 
        @graphics.sleep_delay(10)
        @graphics.rotate_palette
      end
      
      puts "Looping end game."
      loop_active = true

      input = Input::BreakCallback.make_control{ loop_active = false }

      @graphics.prepare_scrolltext( END_GAME_TEXT )

      
      # Cycle some of the colours.
      while loop_active do
        @graphics.sleep_delay(10)
        @graphics.update_scrolltext
        @graphics.rotate_palette
        @graphics.flip
        input.check_input
      end

      @sound.play_sound( :zap )

      puts "Fade out end game."
      @graphics.put_screen( :endscreen )
      @graphics.fade_out do 
        @graphics.sleep_delay(10)
        @graphics.rotate_palette

      end
      @graphics.clear_screen
      @graphics.flip

      @graphics.set_palette( nil )

      @state = :stopped_game
      
    end


    def select_game_checkpoint
      level, status = @saved_checkpoints.max
      start_game( level, status )      
    end



    ##
    # Check whether we have hit a "special" level, such as the end.
    #
    def check_level( level )
      if level > NUM_LEVELS
        @state = :endgame
        false
      else
        true
      end
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
	File.open(@savegame_filename,'r') do|file|
	  obj = YAML.load( file )	  
	  checkpoints = obj if obj.kind_of? Hash 
	end
      rescue Exception => e
	puts "Error reading checkpoints: " + e.inspect	
      end      
      @saved_checkpoints = checkpoints
    end

    ##
    # Save the list of checkpoints to file.
    # I.e. the savegames.
    def save_checkpoints
      failures = 0 # To avoid loops
      begin
	File.open(@savegame_filename,'w') do|file|
	  puts "Saving checkpoints..."
	  file.puts @saved_checkpoints.to_yaml
	end
      rescue Errno::ENOENT => e
	puts "Error saving checkpoints: " + e.inspect	
        basedir = File.dirname(@savegame_filename)
        if Dir[basedir].empty? and failures.zero? then
          puts "Directory seems missing, trying to create: #{basedir}"
          Dir.mkdir(basedir)
          puts "Retry saving checkpoints..."
          failures+=1 
          retry
        end
      rescue Exception => e
	puts "Error saving checkpoints: " + e.inspect
        failures+=1	
      end            
    end
      
  end # Game
  
end # MagicMaze



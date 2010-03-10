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

require 'magicmaze/filemap'
require 'magicmaze/movement'
require 'magicmaze/player'

require 'magicmaze/graphics'

module MagicMaze

  ##
  # Methods for drawing the map.
  module DrawLoop
  
     def follow_entity(leader)
      # puts "Following #{leader}..."
      time_synchronized_drawing do
	draw(leader.location)
      end
      return true
    end

    def time_synchronized_drawing
      @graphics.time_synchronized(@game_delay) do 
	yield
	@graphics.flip
      end
    end

    def draw_now
      draw ; @graphics.flip
    end


    def draw(where=@player.location)
      draw_maze( where.x, where.y )
      # @graphics.update_player( @player.direction.value )
      draw_hud
    end


    def draw_hud
      @graphics.update_spells(primary_spell.sprite_id, 
                              secondary_spell.sprite_id )
      @graphics.write_score( get_score ) 
      @graphics.update_life_and_mana( get_life, get_mana )
      @graphics.update_inventory( get_inventory )

    end

    def draw_maze( curr_x, curr_y )
      @graphics.update_view_rows(curr_y)do |current_y|
        @graphics.update_view_columns(curr_x)do |current_x|
          @map.each_tile_at( current_x, current_y ) do |tile|
            @graphics.update_view_block( tile.sprite_id ) if tile
          end
        end
      end
    end
    
    def alternative_inner_drawing
      @map.all_tiles_at( current_x, current_y ) do
        |background, object, entity, spiritual|
        # background = @map.background.get(current_x,current_y)
        @graphics.update_view_background_block( background.sprite_id )
        # object = @map.object.get(current_x,current_y)
        @graphics.update_view_block( object.sprite_id ) if object
        # entity = @map.entity.get(current_x,current_y)
        @graphics.update_view_block( entity.sprite_id ) if entity
      end
    end

  
  end

  ##
  # Methods for accessing player
  module PlayerAccessors
    def next_primary_spell
      @player.spellbook.page_spell( :primary )
    end
    def previous_primary_spell
      @player.spellbook.page_spell( :primary, -1)
    end
    def next_secondary_spell
      @player.spellbook.page_spell( :secondary )
    end
    def previous_secondary_spell
      @player.spellbook.page_spell( :secondary, -1)
    end

    def cast_primary_spell
      primary_spell.cast_spell( @player )
    end
    def cast_alternative_spell
      secondary_spell.cast_spell( @player )
    end

    ##
    # Getters
    def primary_spell
      @player.spellbook.spell( :primary )
    end
    def secondary_spell
      @player.spellbook.spell( :secondary )
    end


    def get_score
      @player.score
    end
    def get_inventory
      @player.inventory
    end
    def get_life
      @player.life
    end
    def get_mana
      @player.mana
    end
  end



  module MovementHandling
    def move_up
      turn_and_move( Direction::NORTH )
    end
    def move_down
      turn_and_move( Direction::SOUTH )
    end
    def move_left
      turn_and_move( Direction::WEST )
    end
    def move_right
      turn_and_move( Direction::EAST )
    end

    def turn_and_move( dir )
      @movement |= (1<<dir.value)
    end

    def calc_movement
      # cancelation of opposite moves instead
      # of flickering like mad.
      [0b1010, 0b0101].each{|cancel|
        if @movement&cancel==cancel
          @movement^=cancel
        end
      }
      4.times{|m|
        if @movement & 1 != 0
          old_turn_and_move(m)
        end
        @movement >>=1
      }
    end

    def old_turn_and_move( dir )
      if @player.direction.value == dir
        @player.add_impulse(:move_forward)
      else
        @player.add_impulse(:turn_around, dir )
      end
    end
  end


  ##################################
  # Main game loop.
  class GameLoop
    include DrawLoop
    include PlayerAccessors
    include MovementHandling

    attr_reader :graphics, :sound, :input

    def initialize( game_config, level = 1, player_status = nil )
      @game_config = game_config
      @graphics    = game_config.graphics
      @sound       = game_config.sound
      @input = @game_input  = Input::Control.new( self, :in_game )
      @game_delay  = 50
      @level = level
      if player_status == :training then
	puts "Entering training mode..."
	@training_mode = true
	player_status = nil
      end
      @restart_status = player_status

      @map = nil
      @player = nil
    end
    
    def load_map( level = 1, saved = nil )
      puts "Loading level: %s" % level
      filename = level
      filename = sprintf("data/maps/mm_map.%03d",level
                         ) if level.kind_of? Numeric
      filemap = MagicMaze::FileMap.new( filename )

      @map_title = filemap.title

      yield level, @map_title

      @map.purge if @map # Clean up old map, if any.

      @level = level
      @map = filemap.to_gamemap

      should_reset = @player || @restart_status
      @player = Player.new( @map, self )  unless @player
      @player.reset( @map, @restart_status )  if should_reset
      @restart_status = nil

      unless @training_mode then
	@saved_player_status = @player.get_saved
	@game_config.update_checkpoint( level, @saved_player_status )
      end

      GC.start
    end



    ##
    # Actions
    
    def toogle_fullscreen
      @graphics.toogle_fullscreen
    end


    ##
    # Refactored block form for all actions that require verification. 
    #
    def really_do?( message )
      @graphics.show_long_message( message + "\n" + _("[Y/N]") )
      if @game_input.get_yes_no_answer
	yield
      end
    end

    def escape
      really_do?(_("Quit game?")) do
	@state = :stopped_game
      end
    end

    def save_game
      @game_config.save_checkpoints
    end

    def pause_game
      @graphics.show_long_message( _("Paused!\n\nPress any key\nto resume game.") )
      @game_input.get_key_press
    end

    def increase_volume
      @sound.change_volume( 1 )
      @sound.play_sound( :bonus )
    end

    def decrease_volume
      @sound.change_volume( -1 )
      @sound.play_sound( :bonus )
    end

    def increase_speed
      @game_delay -= 5 if @game_delay > 10      
      puts "Game delay: #@game_delay"
    end

    def decrease_speed
      @game_delay += 5 if @game_delay < 100      
      puts "Game delay: #@game_delay"
    end


   def helpscreen
     @graphics.show_help
     @game_input.get_key_press
     @graphics.put_screen( :background, false, false )
    end

    def restart_level
      really_do?(_("Restart level?")) do
	@state = :restart_level
      end
    end


    def process_entities
      alive = @player.action_tick
      game_data = { 
        :player_location => @player.location
      }
      @map.active_entities.each_tick( game_data )
    end


    def game_loop
      puts "Game loop"  
      
      # Fade in the background
      @graphics.put_screen( :background, false, false )
      draw_now
      @graphics.fade_in

      @state = :game_loop
      while @state == :game_loop

        @graphics.time_synchronized(@game_delay) do 
	  draw_now

	  @movement = 0
	  @game_input.check_input
	  calc_movement
	  
	  @state = catch( :state_change ) do 
            process_entities
	    @state
	  end
	end
      end


      # Fade out.
      @graphics.put_screen( :background, false, false )
      draw_now
      puts "Game loop fade out..."
      @graphics.fade_out do  
	@graphics.sleep_delay(1)
      end
      
      # Clear screen for returning to the title loop
      @graphics.clear_screen
      @graphics.flip
      @graphics.clear_screen

      @state
    end # loop
    protected :game_loop

    def start
      begin
	@graphics.time_synchronized(1000) do
	  load_map( @level ) do |level, map_title |
	    # Loading message as soon as title has been loaded.
	    loading_message = _("Entering level %s") % level.to_s + 
	      "\n" + _(map_title) + "\n"+ _("Get ready!")
	    @graphics.clear_screen
	    @graphics.show_long_message(loading_message, false, :fullscreen )
	    @graphics.fade_in
	  end
	end
	@graphics.fade_out



        game_loop
        case @state
        when :next_level  
          @level += 1 
          unless @game_config.check_level( @level ) 
            @state = :endgame
          end
	when :restart_level
	  @restart_status = @saved_player_status
        when :player_died 
          draw_now
          puts "Score: #{@player.score}"
          sleep 1
	  @restart_status = @saved_player_status
        end
      end while [:next_level,:restart_level,:player_died].include? @state
    end


      
  end # GameLoop


end # MagicMaze

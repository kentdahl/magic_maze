require 'magicmaze/filemap'
require 'magicmaze/movement'
require 'magicmaze/player'

require 'magicmaze/graphics'

module MagicMaze

  class GameLoop
    def initialize( game_config, level = 1 )
      @game_config = game_config
      @graphics    = game_config.graphics
      @sound       = game_config.sound
      @game_input  = Input::Control.new( self, :in_game )
      @game_delay  = 50
      @level = level
    end
    
    def load_map( level = 1 )
      filename = level
      filename = sprintf("data/maps/mm_map.%03d",level
                         ) if level.kind_of? Numeric
      filemap = MagicMaze::FileMap.new( filename )

      @level = level
      @map = filemap.to_gamemap
      if @player
        @player.reset( @map )
      else
        @player = Player.new( @map, @game_config )
      end
      GC.start
    end

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


    ##
    # Actions
    
    def toogle_fullscreen
      @graphics.toogle_fullscreen
    end

    def escape
      puts "Escape"
      @state = :stopped_game
    end

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



    def game_loop
      puts "Game loop"      
      @graphics.put_screen( :background )

      @state = :game_loop
      while @state == :game_loop

        time_start = SDL.get_ticks

        draw_now

        @movement = 0
        @game_input.check_input
        calc_movement

        @state = catch( :state_change ) do 
          alive = @player.action_tick
          @map.active_entities.each_tick
          @state
        end

        time_end = SDL.get_ticks
        delay = @game_delay + time_end - time_start
        SDL.delay(delay) if delay>0
      end
      @state
    end # loop
    protected :game_loop

    def start
      begin
        load_map( @level )
        game_loop
        case @state
        when :next_level  
          @level += 1 
        when :player_died 
          draw_now
          puts "Score: #{@player.score}"
          sleep 1
        end
      end while @state == :next_level
    end


    def draw_now
      draw ; @graphics.flip
    end


    def draw
      draw_maze( @player.location.x, @player.location.y )
      # @graphics.update_player( @player.direction.value )
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

      
  end # GameLoop


end # MagicMaze

############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2024 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'sdl2'


module MagicMaze

  ##
  # module for handling input from the user.
  module Input


    ##
    # Callback for implementing states where 
    # keys can only be used to break out of a loop or similar
    #
    class BreakCallback
      def initialize( block )
        @block = block
      end
      def callback
        @block.call
      end
      alias :break :callback
      def self.make_control( key_mode = :break, &block )
        Control.new( self.new( block ), key_mode )
      end
    end

    ##
    # Control input.
    #
    class Control
      DEFAULT_KEY_MAP = {
        SDL2::Key::F1     => :helpscreen,
        SDL2::Key::H      => :helpscreen,
        SDL2::Key::F4     => :load_game,
        SDL2::Key::F5     => :save_game,
        SDL2::Key::F9     => :restart_level,
        SDL2::Key::R      => :restart_level,

        SDL2::Key::F12    => :toogle_fullscreen,
        SDL2::Key::ESCAPE => :escape,
        SDL2::Key::Q      => :escape,
        SDL2::Key::X      => :next_primary_spell,
        SDL2::Key::Z      => :previous_primary_spell,
        SDL2::Key::S      => :next_secondary_spell,
        SDL2::Key::A      => :previous_secondary_spell,
        SDL2::Key::P      => :pause_game,
        SDL2::Key::R      => :restart_level,

        SDL2::Key::PAGEUP   => :increase_volume,
        SDL2::Key::PAGEDOWN => :decrease_volume,

        SDL2::Key::KP_PLUS   => :increase_speed,
        SDL2::Key::KP_MINUS  => :decrease_speed,

        # For OLPC 
        SDL2::Key::KP_3   => :next_primary_spell,     # X
        SDL2::Key::KP_7   => :next_secondary_spell,   # []
       
      }
      DEFAULT_ACTION_KEY_MAP = {
        SDL2::Key::Scan::SPACE  => :cast_alternative_spell,
        SDL2::Key::Scan::UP     => :move_up,
        SDL2::Key::Scan::DOWN   => :move_down,
        SDL2::Key::Scan::LEFT   => :move_left,
        SDL2::Key::Scan::RIGHT  => :move_right,   
        
        # For OLPC 
        SDL2::Key::Scan::KP_8   => :move_up,
        SDL2::Key::Scan::KP_2   => :move_down,
        SDL2::Key::Scan::KP_4   => :move_left,
        SDL2::Key::Scan::KP_6   => :move_right,      

        # For OLPC 
        SDL2::Key::Scan::KP_1   => :cast_primary_spell,     # V
        SDL2::Key::Scan::KP_9   => :cast_alternative_spell, # O

  

      }
      DEFAULT_MODIFIER_KEY_MAP = {
        SDL2::Key::Mod::LCTRL  => :cast_primary_spell,
        SDL2::Key::Mod::LALT   => :cast_alternative_spell,

      }
      DEFAULT_JOYSTICK_MAP = {
        :hat => {
          SDL2::Joystick::Hat::UP    => :move_up,
          SDL2::Joystick::Hat::DOWN  => :move_down,
          SDL2::Joystick::Hat::LEFT  => :move_left,
          SDL2::Joystick::Hat::RIGHT => :move_right,
        },
        :button => {
          0 => :cast_primary_spell,
          1 => :cast_alternative_spell,
          2 => :next_primary_spell,
          3 => :previous_primary_spell,
          4 => :next_secondary_spell,
          5 => :previous_secondary_spell,
        },
        :axis => {
          0 => [:move_left, :move_right],
          1 => [:move_up, :move_down],
          2 => [:previous_secondary_spell, nil],
          3 => [:next_secondary_spell, nil],
        }
        
      }

      EMPTY_KEY_MAP = {}


      ##
      # Default key maps. 
      # We have maps for in game and titlescreen input.
      # Each key map has :normal_keys, :action_keys and :modifier_keys.
      # - :normal_keys are triggered on release (nice for quit/exit/help etc)
      # - :action_keys are triggered when held (nice for movement etc)
      # - :modifier_keys are also triggered when held, but is reserved for
      #   modifier keys (such as Ctrl, Alt, Shift etc)
      KEY_MAPS = {
        :in_game => { 
          :normal_keys => DEFAULT_KEY_MAP, 
          :action_keys => DEFAULT_ACTION_KEY_MAP,
          :modifier_keys => DEFAULT_MODIFIER_KEY_MAP,
          :joystick => DEFAULT_JOYSTICK_MAP,
        },
        :titlescreen => {
          :normal_keys => {
            SDL2::Key::F1     => :test_helpscreen,
            SDL2::Key::F4     => :select_game_checkpoint,
            SDL2::Key::F6     => :test_fade,
            SDL2::Key::F7     => :test_endgame,
            SDL2::Key::F8     => :test_menu,

            SDL2::Key::F12    => :toogle_fullscreen,
            SDL2::Key::ESCAPE => :exit_game,
            SDL2::Key::Q      => :exit_game,
            SDL2::Key::RETURN => :open_game_menu,
            SDL2::Key::SPACE  => :open_game_menu,

            # For OLPC:
            SDL2::Key::KP_3   => :exit_game,      # X
            SDL2::Key::KP_1   => :open_game_menu, # V
            SDL2::Key::KP_7   => :start_game,     # 


          },
          :action_keys => { },
          :modifier_keys => EMPTY_KEY_MAP,
          :joystick => {
            :button => {
              0 => :start_game,
            }
          }
        },
        :break => {
          :normal_keys => {
            SDL2::Key::ESCAPE => :break,
            SDL2::Key::Q      => :break,
            SDL2::Key::RETURN => :break,
            SDL2::Key::SPACE  => :break,
            SDL2::Key::KP_3    => :break,     # X

          },
          :action_keys => EMPTY_KEY_MAP,
          :modifier_keys => EMPTY_KEY_MAP,
          :joystick => {
            :button => {
              0 => :break,
            }
          }

        },
        
      
      }


      @@joystick = nil

      def self.init_joystick( joy_num = 0)
        puts "Checking for joystick"
        SDL2.init( SDL2::INIT_JOYSTICK )
        if SDL2::Joystick.num_connected_joysticks > joy_num then
          puts "Enabling joystick"
          @@joystick = SDL2::Joystick.open( joy_num )
          puts "Joystick: " + SDL2::Joystick.indexName( @@joystick.index )
        end
      end

      
      attr_accessor :callback
      def initialize( callback, key_mode = :titlescreen )
        # WAS: SDL2::Key.enable_key_repeat( 10, 10 )
        @callback = callback
        set_key_mode( key_mode )

      end

      ##
      # set a key mode.
      def set_key_mode( key_mode )
        @keymap = KEY_MAPS[ key_mode ]
      end


      def get_key_press
        begin
          event = SDL2::Event.poll
        end until event.kind_of? SDL2::Event::KeyUp
        return event
      end


      YES_NO_ANSWERS = {
        SDL2::Key::ESCAPE => false,
        SDL2::Key::Q => false,
        SDL2::Key::N => false,
        SDL2::Key::Y => true,
        SDL2::Key::J => true,
        # For OLPC:
        SDL2::Key::KP_3   => false,    # X
        SDL2::Key::KP_1   => true,     # V
      }

      def get_yes_no_answer
        answers = YES_NO_ANSWERS
        begin
          key = get_key_press.sym
        end until answers.has_key?( key )
        return answers[ key ]
      end


      MENU_NAVIGATION = {
        SDL2::Key::ESCAPE => :exit_menu,
        SDL2::Key::Q      => :exit_menu,
        SDL2::Key::UP     => :previous_menu_item,
        SDL2::Key::DOWN   => :next_menu_item,
        SDL2::Key::RETURN => :select_menu_item,
        SDL2::Key::SPACE  => :select_menu_item,
        # For OLPC:
        SDL2::Key::KP_3   => :exit_menu,         # X
        SDL2::Key::KP_1   => :select_menu_item,  # V
        SDL2::Key::KP_8   => :previous_menu_item,
        SDL2::Key::KP_2   => :next_menu_item,
      }

      def get_menu_item_navigation_event
        answers = MENU_NAVIGATION
        begin
          key = get_key_press.sym
        end until answers.has_key?( key )
        return answers[ key ]
      end




      
      def check_input
        event = SDL2::Event.poll
        case event
        when SDL2::Event::Quit then @callback.exit
        when SDL2::Event::KeyUp
          check_key_press( event.sym )        
        end
        check_key_hold
        check_modifier_keys
        check_joystick
      end
      
      ##
      # send a callback if it can handle it
      def call_callback( method_name )
        @callback.send( method_name ) if method_name and @callback.respond_to? method_name
      end
      ##
      # Check for seldom key presses.
      def check_key_press( key )
        method_name = @keymap[:normal_keys][ key ]
        call_callback( method_name )
      end
      
      ## 
      # Check for action keys that often will be pressed
      # and may be held down.
      def check_key_hold
        # WAS: SDL2::Key.scan
        @keymap[:action_keys].each do |key, action|
          if SDL2::Key.pressed?( key )
            call_callback( action )
          end
        end
      end

      ##
      # Check for modifier keys (Ctrl, Shift etc)
      def check_modifier_keys
        mod_state = SDL2::Key::Mod.state
        @keymap[:modifier_keys].each do |key, action|
          if (mod_state & key) != 0 then
             call_callback( action )
          end
        end
      end

      ##
      # Check for joystick movement
      def check_joystick
        return unless @@joystick
        SDL2::Joystick.updateAll
        joymap = @keymap[:joystick]
        
        # Check hat state...
        joy_hat_state = @@joystick.hat(0)
        joymap[:hat].each do |hat, action|
          if (joy_hat_state & hat) != 0 then
            call_callback( action )
          end
        end if joymap[:hat]
        
        # Check buttons...
        joymap[:button].each do |button, action|
          if( @@joystick.button( button ) )
             call_callback( action )
          end
        end if joymap[:button]

        # Check axis
        joymap[:axis].each do |axis, action_list|
          axis_value = @@joystick.axis( axis )
          action = nil
          action = action_list.first if axis_value < -(1<<8)
          action = action_list.last  if axis_value > (1<<8)
          call_callback( action ) if action
        end if joymap[:axis]

      end


    end # Control
    
  end # Input

end # MagicMaze

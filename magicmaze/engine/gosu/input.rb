############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2013 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'gosu'


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
        Gosu::KbF1     => :helpscreen,
        Gosu::KbH      => :helpscreen,
        Gosu::KbF4     => :load_game,
        Gosu::KbF5     => :save_game,
        Gosu::KbF9     => :restart_level,
        Gosu::KbR      => :restart_level,

        Gosu::KbF12    => :toogle_fullscreen,
        Gosu::KbEscape => :escape,
        Gosu::KbQ      => :escape,
        Gosu::KbX      => :next_primary_spell,
        Gosu::KbZ      => :previous_primary_spell,
        Gosu::KbS      => :next_secondary_spell,
        Gosu::KbA      => :previous_secondary_spell,
        Gosu::KbP      => :pause_game,
        Gosu::KbR      => :restart_level,

        Gosu::KbPageUp   => :increase_volume,
        Gosu::KbPageDown => :decrease_volume,

        #Gosu::KbNumpadPlus   => :increase_speed,
        #Gosu::KbNumpadMinus  => :decrease_speed,

                Gosu::KbSpace  => :cast_alternative_spell,
        Gosu::KbUp     => :move_up,
        Gosu::KbDown   => :move_down,
        Gosu::KbLeft   => :move_left,
        Gosu::KbRight  => :move_right,   


        # For OLPC 
        Gosu::KbNumpad3   => :next_primary_spell,     # X
        Gosu::KbNumpad7   => :next_secondary_spell,   # []
       
      }
      DEFAULT_ACTION_KEY_MAP = {
        Gosu::KbSpace  => :cast_alternative_spell,
        Gosu::KbUp     => :move_up,
        Gosu::KbDown   => :move_down,
        Gosu::KbLeft   => :move_left,
        Gosu::KbRight  => :move_right,   
        
        # For OLPC 
        Gosu::KbNumpad8   => :move_up,
        Gosu::KbNumpad2   => :move_down,
        Gosu::KbNumpad4   => :move_left,
        Gosu::KbNumpad6   => :move_right,      

        # For OLPC 
        Gosu::KbNumpad1   => :cast_primary_spell,     # V
        Gosu::KbNumpad9   => :cast_alternative_spell, # O

  

      }
      DEFAULT_MODIFIER_KEY_MAP = {
        #Gosu::KbMOD_LCTRL  => :cast_primary_spell,
        #Gosu::KbMOD_LALT   => :cast_alternative_spell,

      }
      DEFAULT_JOYSTICK_MAP = {
        :hat => {
          #SDL::Joystick::HAT_UP    => :move_up,
          #SDL::Joystick::HAT_DOWN  => :move_down,
          #SDL::Joystick::HAT_LEFT  => :move_left,
          #SDL::Joystick::HAT_RIGHT => :move_right,
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
            Gosu::KbF1     => :test_helpscreen,
            Gosu::KbF4     => :select_game_checkpoint,
            Gosu::KbF6     => :test_fade,
            Gosu::KbF7     => :test_endgame,
            Gosu::KbF8     => :test_menu,

            Gosu::KbF12    => :toogle_fullscreen,
            Gosu::KbEscape => :exit_game,
            Gosu::KbQ      => :exit_game,
            Gosu::KbReturn => :open_game_menu,
            Gosu::KbSpace  => :open_game_menu,

            # For OLPC:
            Gosu::KbNumpad3   => :exit_game,      # X
            Gosu::KbNumpad1   => :open_game_menu, # V
            Gosu::KbNumpad7   => :start_game,     # 


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
            Gosu::KbEscape => :break,
            Gosu::KbQ      => :break,
            Gosu::KbReturn => :break,
            Gosu::KbSpace  => :break,
            Gosu::KbNumpad3    => :break,     # X

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
      end

      
      attr_accessor :callback
      def initialize( callback, key_mode = :titlescreen )
        # SDL::Key.enable_key_repeat( 10, 10 )
        @callback = callback
        set_key_mode( key_mode )

      end

      ##
      # set a key mode.
      def set_key_mode( key_mode )
        @keymap = KEY_MAPS[ key_mode ]
      end


      def get_key_press
        #begin
        #  event = SDL::Event2.poll
        #end until event.kind_of? SDL::Event2::KeyUp
        return event
      end


      YES_NO_ANSWERS = {
        Gosu::KbEscape => false,
        Gosu::KbQ => false,
        Gosu::KbN => false,
        Gosu::KbY => true,
        Gosu::KbJ => true,
        # For OLPC:
        Gosu::KbNumpad3   => false,    # X
        Gosu::KbNumpad1   => true,     # V
      }

      def get_yes_no_answer
        answers = YES_NO_ANSWERS
        begin
          key = get_key_press.sym
        end until answers.has_key?( key )
        return answers[ key ]
      end


      MENU_NAVIGATION = {
        Gosu::KbEscape => :exit_menu,
        Gosu::KbQ      => :exit_menu,
        Gosu::KbUp     => :previous_menu_item,
        Gosu::KbDown   => :next_menu_item,
        Gosu::KbReturn => :select_menu_item,
        Gosu::KbSpace  => :select_menu_item,
        # For OLPC:
        Gosu::KbNumpad3   => :exit_menu,         # X
        Gosu::KbNumpad1   => :select_menu_item,  # V
        Gosu::KbNumpad8   => :previous_menu_item,
        Gosu::KbNumpad2   => :next_menu_item,
      }

      def get_menu_item_navigation_event
        answers = MENU_NAVIGATION
        begin
          key = get_key_press.sym
        end until answers.has_key?( key )
        return answers[ key ]
      end




      
      def check_input      
        #event = SDL::Event2.poll
        #case event
        #when SDL::Event2::Quit then @callback.exit
        #when SDL::Event2::KeyUp
        #  check_key_press( event.sym )        
        #end
        check_key_hold
        check_modifier_keys
        check_joystick
      end
      
      ##
      # send a callback if it can handle it
      def call_callback( method_name )
        return nil unless method_name && @callback.respond_to?(method_name)
        puts "event callback: #{method_name.to_s}"
        @callback.send( method_name )
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
        #SDL::Key.scan
        @keymap[:action_keys].each do |key, action|
          #if SDL::Key.press?( key )
          #  call_callback( action )
          #end
        end
      end

      ##
      # Check for modifier keys (Ctrl, Shift etc)
      def check_modifier_keys
        #mod_state = SDL::Key.mod_state
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
        SDL::Joystick.updateAll
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

require 'sdl'


module MagicMaze

  ##
  # module for handling input from the user.
  module Input

    class Control
      DEFAULT_KEY_MAP = {
        SDL::Key::F1     => :helpscreen,
        SDL::Key::F12    => :toogle_fullscreen,
        SDL::Key::ESCAPE => :escape,
        SDL::Key::Q      => :escape,
        SDL::Key::X      => :next_primary_spell,
        SDL::Key::Z      => :previous_primary_spell,
        SDL::Key::S      => :next_secondary_spell,
        SDL::Key::A      => :previous_secondary_spell,

        
      }
      DEFAULT_ACTION_KEY_MAP = {
        SDL::Key::SPACE  => :cast_alternative_spell,
        SDL::Key::UP     => :move_up,
        SDL::Key::DOWN   => :move_down,
        SDL::Key::LEFT   => :move_left,
        SDL::Key::RIGHT  => :move_right,        
      }
      DEFAULT_MODIFIER_KEY_MAP = {
        SDL::Key::MOD_LCTRL  => :cast_primary_spell,
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
        },
        :titlescreen => {
          :normal_keys => {
            SDL::Key::F12    => :toogle_fullscreen,
            SDL::Key::ESCAPE => :exit_game,
            SDL::Key::Q      => :exit_game,
            SDL::Key::RETURN => :start_game,
            SDL::Key::SPACE  => :start_game,
          },
          :action_keys => { },
          :modifier_keys => EMPTY_KEY_MAP,
        }
      }
      
      attr_accessor :callback
      def initialize( callback, key_mode = :titlescreen )
        SDL::Key.enable_key_repeat( 10, 10 )
        @callback = callback
        set_key_mode( key_mode )
      end

      ##
      # set a key mode.
      def set_key_mode( key_mode )
        @keymap = KEY_MAPS[ key_mode ]
      end

      
      def check_input      
        event = SDL::Event2.poll
        case event
        when SDL::Event2::Quit then @callback.exit
        when SDL::Event2::KeyUp
          check_key_press( event.sym )        
        end
        check_key_hold
        check_modifier_keys
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
        SDL::Key.scan
        @keymap[:action_keys].each do |key, action|
          if SDL::Key.press?( key )
            call_callback( action )
          end
        end
      end

      ##
      # Check for modifier keys (Ctrl, Shift etc)
      def check_modifier_keys
        mod_state = SDL::Key.mod_state
        @keymap[:modifier_keys].each do |key, action|
          if (mod_state & key) != 0 then
             call_callback( action )
          end
        end
      end
    end # Control
    
  end # Input

end # MagicMaze

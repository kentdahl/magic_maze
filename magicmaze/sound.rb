require 'sdl'

module MagicMaze
  ################################################
  #
  SOUND_ENABLED = true unless defined? SOUND_ENABLED 
  if SOUND_ENABLED then
    class Sound
      def initialize
        SDL::Mixer.open
        @sounds = {}
        (1..4).each{|sound_no|
        filename = sprintf "data/sound/sound%d.wav", sound_no
          sound = SDL::Mixer::Wave.load( filename )
          @sounds[sound_no] = sound
        }
      end
      
      def play_sound( sound_no )
        sound_no = SOUNDS[sound_no] unless sound_no.kind_of? Numeric
        wave = @sounds[sound_no]
        SDL::Mixer.playChannel(sound_no,wave,0)
      end
      
    end
  else
    class Sound;def play_sound(*a);end;end
  end
  
  SOUNDS = {
    :argh  => 1,
    :zap   => 2,
    :punch => 3,
    :bonus => 4,
  }


end

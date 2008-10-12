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

require 'sdl'

module MagicMaze
  ################################################
  #
  # SOUND_ENABLED = true unless defined? SOUND_ENABLED 

  ##
  # Use SDL for sound
  #
  class SDLSound
    ALL_CHANNELS = -1
    def initialize(options={})
      SDL::Mixer.open
      @sounds = {}
      (1..4).each{|sound_no|
        filename = sprintf "data/sound/sound%d.wav", sound_no
	sound = SDL::Mixer::Wave.load( filename )
	@sounds[sound_no] = sound
      }
      volume = options[:volume] || 8
      SDL::Mixer.set_volume( ALL_CHANNELS, 64*volume/10 )
    end
    
    def play_sound( sound_no )
        sound_no = SOUNDS[sound_no] unless sound_no.kind_of? Numeric
      wave = @sounds[sound_no]
      SDL::Mixer.playChannel(sound_no,wave,0)
    end

    def change_volume( way = 1, step = 8 )
      old_vol = SDL::Mixer.set_volume( ALL_CHANNELS, -1 )
      new_vol = old_vol + way * step
      if new_vol.between?( 1, 128 )
	SDL::Mixer.set_volume( ALL_CHANNELS, new_vol )
      end
    end
    
  end

  ##
  # Dummy class for when we want no sound.
  class NoSound
    def method_missing(*a)
    end
  end
    
  ##
  # Mapping sound names to sound file index.
  #
  SOUNDS = {
    :argh  => 1,
    :zap   => 2,
    :punch => 3,
    :bonus => 4,
  }

end

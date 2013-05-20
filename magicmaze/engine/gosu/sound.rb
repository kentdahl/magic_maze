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
  ################################################
  #
  # SOUND_ENABLED = true unless defined? SOUND_ENABLED 

  ##
  # Use SDL for sound
  #
  class Sound
    ALL_CHANNELS = -1

    ##
    # Singleton graphics instance.
    def self.get_sound(options={})
      @sound_instance ||= MagicMaze::Sound.new(options)
      @sound_instance
    end

    def self.shutdown_graphics
      @sound_instance.destroy
      @sound_instance = nil
    end


    def initialize(options={})
    end
    
    def destroy
    end

    def play_sound( sound_no )
    end

    def change_volume( way = 1, step = 8 )
    end
    
  end

end

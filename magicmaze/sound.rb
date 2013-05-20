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


module MagicMaze
  ################################################
  #
  # SOUND_ENABLED = true unless defined? SOUND_ENABLED 

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

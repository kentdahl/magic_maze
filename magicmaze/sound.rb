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


  class Sound
    DATA_DIR_PATH='data/'
    SND_PATH = 'data/sound/'


    def get_options
      @options
    end

    def data_dir_path
      @data_dir_path ||= get_data_dir_path
    end

    def get_data_dir_path
      options = get_options || {}
      options[:datadir] || DATA_DIR_PATH
    end

    def get_data_dir_path_to(filename)
      get_data_dir_path + filename
    end

    def snd_path
      @snd_path ||= get_snd_path
    end

    def get_snd_path
      data_dir = data_dir_path
      data_dir ? (data_dir + 'sound/') : SND_PATH
    end

    def snd_path_to(filename)
      snd_path + filename
    end
  end

end

#!/usr/bin/ruby -I.

module MagicMaze ; end

require 'getoptlong'

options = GetoptLong.new( ["--nosound", GetoptLong::NO_ARGUMENT] )
options.each do |option, argument|
  
  case option
  when "--nosound"
    MagicMaze::SOUND_ENABLED = false
  end

end			 


require 'magicmaze/magicmaze'

MagicMaze::Game.new.loop


#!/usr/bin/ruby -I.

module MagicMaze ; end

require 'getoptlong'

options = GetoptLong.new( ["--nosound", GetoptLong::NO_ARGUMENT],
			  ["--level",   GetoptLong::REQUIRED_ARGUMENT] )

opt_hash = {
  :sound => true,
}

options.each do |option, argument|  
  case option
  when "--nosound"
    opt_hash[ :sound ] = false
  when "--level"
    opt_hash[ :start_level ] = argument.to_i
  end
end			 


require 'magicmaze/magicmaze'

MagicMaze::Game.new( opt_hash ).loop


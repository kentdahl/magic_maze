#!/usr/bin/ruby -I.

require 'getoptlong'

options = GetoptLong.new(["--help",     "-h", GetoptLong::NO_ARGUMENT ], 
                         ["--nosound",  "-S", GetoptLong::NO_ARGUMENT ],
                         ["--level",    "-l", GetoptLong::REQUIRED_ARGUMENT ],
                         ["--joystick", "-j", GetoptLong::OPTIONAL_ARGUMENT ]

 )


def show_usage
  puts <<-USAGE
Magic Maze, a Ruby/SDL game. 

  usage: ruby mm.rb [--help] [--nosound] [--level #] [--joystick [#]]

    -h --help         Show this message
    -j --joystick     Enable joystick support 
    -l --level 	      Assign a start level (1-10)
    -S --nosound      Disables sound
    
    USAGE
end



opt_hash = {
  :sound => true,
}

options.each do |option, argument|  
  case option
  when "--help"
    show_usage
    exit
  when "--nosound"
    opt_hash[ :sound ] = false
  when "--level"
    opt_hash[ :start_level ] = argument.to_i
  when "--joystick"
    opt_hash[ :joystick ] = (argument || 0).to_i
  end
end			 



require 'magicmaze/magicmaze'

MagicMaze::Game.new( opt_hash ).loop


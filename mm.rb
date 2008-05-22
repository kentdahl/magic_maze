#!/usr/bin/ruby -I.

require 'getoptlong'

options = GetoptLong.new(["--help",     "-h", GetoptLong::NO_ARGUMENT ], 
                         ["--nosound",  "-S", GetoptLong::NO_ARGUMENT ],
                         ["--debug",    "-d", GetoptLong::NO_ARGUMENT ],
                         ["--fullscreen",    "-f", GetoptLong::NO_ARGUMENT ],
                         ["--scale",    "-s", GetoptLong::REQUIRED_ARGUMENT ],
                         ["--level",    "-l", GetoptLong::REQUIRED_ARGUMENT ],
                         ["--volume",   "-v", GetoptLong::REQUIRED_ARGUMENT ],
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
    -v --volume       Set volume (1-10)
    -f --fullscreen   Start in fullscreen mode
    -s --scale        Scale the graphics and resolution up (1-5)
    
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
  when "--volume"
    opt_hash[ :volume ] = (argument || 5).to_i
  when "--level"
    opt_hash[ :start_level ] = argument.to_i
  when "--joystick"
    opt_hash[ :joystick ] = (argument || 0).to_i
  when "--debug"
    opt_hash[:debug] = true
  when "--fullscreen"
    opt_hash[:fullscreen] = true
  when "--scale"
    scale = (argument || 1).to_i
    unless ((1..5).include? scale) then 
      raise ArgumentError.new("Invalid scale.") 
    end
    opt_hash[:scale] = scale    
    OVERRIDE_GRAPHICS_SCALE_FACTOR = scale 
    module MagicMaze
      class Graphics
        OVERRIDE_GRAPHICS_SCALE_FACTOR = OVERRIDE_GRAPHICS_SCALE_FACTOR
      end
    end

  end
end			 



require 'magicmaze/magicmaze'

MagicMaze::Game.new( opt_hash ).loop


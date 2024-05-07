############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2024 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'getoptlong'

module MagicMaze

  class CLI

    def get_cli_options
      GetoptLong.new(*CLI_OPTIONS)
    end

    CLI_OPTIONS = [
      ["--help",     "-h", GetoptLong::NO_ARGUMENT ], 
      ["--nosound",  "-S", GetoptLong::NO_ARGUMENT ],
      ["--debug",    "-d", GetoptLong::NO_ARGUMENT ],
      ["--fullscreen",    "-f", GetoptLong::NO_ARGUMENT ],
      ["--scale",    "-s", GetoptLong::REQUIRED_ARGUMENT ],
      ["--engine",    "-e", GetoptLong::REQUIRED_ARGUMENT ],
      ["--level",    "-l", GetoptLong::REQUIRED_ARGUMENT ],
      ["--loadgame", "-L", GetoptLong::NO_ARGUMENT ],
      ["--volume",   "-v", GetoptLong::REQUIRED_ARGUMENT ],
      ["--joystick", "-j", GetoptLong::OPTIONAL_ARGUMENT ],
      ["--savedir",  "-D", GetoptLong::REQUIRED_ARGUMENT ],
      ["--datadir",  "-A",   GetoptLong::REQUIRED_ARGUMENT ],
      ["--editor", "-E", GetoptLong::NO_ARGUMENT ],
      ["--map",  "-m", GetoptLong::REQUIRED_ARGUMENT ]
    ]

    def show_usage
      puts <<-USAGE
    Magic Maze, a Ruby/SDL game. 

      usage: ruby mm.rb [--help] [--nosound] [--level #] [--joystick [#]]

        -h --help         Show this message
        -j --joystick     Enable joystick support 
        -l --level        Assign a start level (1-10)
        -L --loadgame     Load savegame automatically
        -D --savedir      Specify savegame directory
        -A --datadir      Asset data directory path
        -S --nosound      Disables sound
        -v --volume       Set volume (1-10)
        -f --fullscreen   Start in fullscreen mode
        -s --scale        Scale the graphics and resolution up (1-5)
        -E --editor       Experimental map-editor
        -m --map          Map file to open in map-editor

        USAGE
    end

    attr_accessor :default_option_settings

    def parse_options
      options = get_cli_options

      opt_hash = self.default_option_settings || {
        :sound => true
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
          opt_hash[ :start_level ] = Integer(argument)
        when "--loadgame"
          opt_hash[:loadgame] = true
        when "--joystick"
          opt_hash[ :joystick ] = (argument || 0).to_i
        when "--debug"
          opt_hash[:debug] = true
        when "--fullscreen"
          opt_hash[:fullscreen] = true
        when "--editor"
          opt_hash[:editor] = true
        when "--map"
          opt_hash[:map] = argument
        when "--savedir"
          opt_hash[:savedir] = argument
        when "--datadir"
          opt_hash[:datadir] = argument
        when "--scale"
          scale = (argument || 1).to_i
          unless ((1..5).include? scale) then
            raise ArgumentError.new("Invalid scale.")
          end
          opt_hash[:scale] = scale
          # OVERRIDE_GRAPHICS_SCALE_FACTOR = scale
          # module ::MagicMaze
          #   class Graphics
          #     OVERRIDE_GRAPHICS_SCALE_FACTOR = OVERRIDE_GRAPHICS_SCALE_FACTOR
          #   end
          # end
        when "--engine"
          engine = (argument)
          opt_hash[:engine] = engine
          # OVERRIDE_GRAPHICS_ENGINE = engine
        end
      end

      return opt_hash
    end

  end # CLI

end

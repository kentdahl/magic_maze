#!/usr/bin/env ruby

############################################################
# This game is FREE as in both BEER and SPEECH. It is available and can 
# be distributed under the terms of the GPL license (version 2) or 
# alternatively the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
#
#  Magic Maze - a simple and low-tech monster-bashing maze game.
#  Copyright (C) 2004-2008 Kent Dahl
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
############################################################

require 'magicmaze/cli'

cli = MagicMaze::CLI.new

cli.default_option_settings = {sound: true}

options_data = cli.parse_options


## TODO: Needs special handling here? Changes done at top-level not propagating out?
if options_data[:scale] then
  scale = options_data[:scale]
  OVERRIDE_GRAPHICS_SCALE_FACTOR = scale
  module MagicMaze
    class Graphics
      OVERRIDE_GRAPHICS_SCALE_FACTOR = ::OVERRIDE_GRAPHICS_SCALE_FACTOR
    end
  end
end
if options_data[:engine] then
  engine = options_data[:engine]
  OVERRIDE_GRAPHICS_ENGINE = engine
end


require 'magicmaze/magicmaze'

MagicMaze::Game.new( options_data ).loop


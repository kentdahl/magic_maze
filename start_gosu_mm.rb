#!/usr/bin/env ruby -I.


require 'getoptlong'

OVERRIDE_GRAPHICS_ENGINE = 'gosu'

require 'magicmaze/magicmaze'

require 'magicmaze/engine/gosu/game'

MagicMaze::GosuGame.new({sound: true}).loop

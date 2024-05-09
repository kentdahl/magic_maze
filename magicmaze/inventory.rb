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

require 'magicmaze/spelltile'

module MagicMaze

  ##
  # the backpack of our ol' wizard.
  #
  class Inventory
    MAX_KEYS = 3
    tiles = DEFAULT_KEY_TILES
    KEY_TILES = Hash.new
    tiles.each{|hashkey, keytile|
      KEY_TILES[keytile.color] = keytile
    }

    def initialize
      @keys = Hash.new(0)
    end

    def add_key( color )
      have = @keys[color]
      if have<MAX_KEYS
        @keys[color]+=1
      else
        nil
      end
    end

    def each
      KEY_TILES.each{|key, tile|
        @keys[key].times{
          yield tile.sprite_id
        }
      }
    end

    def open_door?( color )
      if @keys[color]>0
        @keys[color]-=1
        true
      else
        false
      end
    end

  end # Inventory

end

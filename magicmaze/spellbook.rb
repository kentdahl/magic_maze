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

require 'magicmaze/spelltile'

module MagicMaze

    ##################################################
    #
    class SpellBook
      SPELL_NAMES = {
        :primary => [:spell_lightning, :spell_bigball, :spell_coolcube],
        :secondary => [:spell_heal, :spell_summon_mana, :spell_magic_map, :spell_spy_eye]
      }
        
      ##
      # takes two hashes containing spell tiles.
      def initialize( primary_spells  = DEFAULT_ATTACK_SPELL_TILES, 
                     secondary_spells = DEFAULT_OTHER_SPELL_TILES,
                     spell_names = SPELL_NAMES)
        @spell_list = Hash.new
        @spell_names = spell_names
        tiles = nil
        insertion = proc {|spell_name| 
          @spell_list[ spell_name ] = tiles[spell_name] 
        }
        tiles = primary_spells
        @spell_names[:primary].each(&insertion)
        tiles = secondary_spells
        @spell_names[:secondary].each(&insertion)
        #:primary => primary_spells,
        #  :secondary => secondary_spells
        #}
        @spell_index = Hash.new(0)
      end

      def spell( spell_type = :primary )
        @spell_list[
          @spell_names[spell_type][ @spell_index[spell_type]] 
        ]
      end

      def primary_spell
	spell( :primary )
      end

      def secondary_spell
        spell( :secondary )
      end

      def page_spell( spell_type = :primary, diff = 1 )
        @spell_index[ spell_type ] += diff
        bound_index!( spell_type )
      end

      def bound_index!( spell_type = :primary )
        index = @spell_index[ spell_type ]
        max = @spell_names[ spell_type ].size
        index = if index<0
                  max + index
                else
                  if index>= max
                    index - max
                  else
                    index
                  end
                end
        @spell_index[ spell_type ] = index
        nil
      end
      private :bound_index!
      
    end # SpellBook

end

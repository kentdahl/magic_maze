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

require 'magicmaze/tile'

module MagicMaze

  ########################################
  ## 
  # Spell tiles. For the Spellbook.
  class SpellTile < Tile
    def initialize(*a)
      @mana_cost = a.pop
      super(*a)
    end

    def have_mana?
      @caster.have_mana?( @mana_cost )
    end

    def use_mana
      @caster.add_mana( - @mana_cost )
    end
    def restore_mana
      @caster.add_mana( @mana_cost )
    end
    
    ##
    # Cast a spell if there is enough mana.
    # Restore the mana if the spell fails.
    # The actual magic is relegated to do_magic.
    def cast_spell( caster, *args )
      @caster = caster
      if have_mana? then 
        do_magic and caster.add_mana( -@mana_cost )
      end
    end      

    # Consume release of trigger key...
    def consume_key_press
      @caster.game_config.input.get_key_press
    end

    ##
    # Return a true value if magic was done.
    def do_magic
      abstract_method_called
    end

  end

  class AttackSpellTile < SpellTile
    attr_reader :damage
    def initialize(*a)
      @damage = a.pop
      @missiles = Array.new
      super(*a)
    end
    def do_magic 
      return false if @missiles.size > 3 
      location = @caster.location
      @caster.play_sound( :zap )
      missile = Missile.new( @caster, location.map, location.x, location.y, self  )
      location.map.add_active_entity( missile )
      @missiles.push( missile )
      true
    end
    def remove_missile( missile )
      @missiles.delete( missile )
    end
  end



  class MagicMapSpellTile < SpellTile
    include SuperInit

    def draw_map_at( location = @caster, flip = true )
      gfx = @caster.game_config.graphics
      gfx.put_screen(:background, false, false)
      gfx.draw_map( location, false )
      @caster.game_config.draw_hud
      gfx.flip if flip
    end

    def do_old_magic 
      draw_map_at( @caster, true )
      consume_key_press # Release of trigger...
      consume_key_press # And another push to return.
      true
    end

    def do_more_magic
      draw_map_at( @caster, true )
      consume_key_press # Release of trigger...
      location = @caster.location
      manifestation = MovableMapManifestation.new( @caster, location.map, location.x, location.y, self  )

      location.map.add_active_entity( manifestation )
      begin
        manifestation.run
      end while manifestation.active?
      manifestation.remove_entity
    end

    def do_magic
      do_more_magic
    end

  end
  
  class HealSpellTile < SpellTile
    def initialize(*a)
      @heal_gain = a.pop
      super(*a)
    end
    def do_magic 
      @caster.heal( @heal_gain )
    end
  end

  class SummonManaSpellTile < SpellTile
    def initialize(*a)
      @mana_gain = a.pop
      @heal_cost = a.pop
      super(*a)
    end
    def cast_spell( caster, *args )
      if  caster.life > @heal_cost +  Player::MAX_LIFE >> 2 and 
          caster.mana + @mana_gain <= Player::MAX_MANA 
      then 
        caster.add_life( -@heal_cost )
        caster.add_mana( @mana_gain )
        true
      else
        false
      end
    end      


  end

  class SpyEyeSpellTile < SpellTile
    include SuperInit    
    def do_magic 
      @caster.game_config.input.get_key_press # Release of trigger...
      @caster.play_sound( :zap )
      location = @caster.location
      eyeball = Eyeball.new( @caster, location.map, location.x, location.y, self  )
      location.map.add_active_entity( eyeball )
      begin
        eyeball.run
      end while eyeball.active?
      eyeball.remove_entity
      true
    end

  end


  ### Default Spells in Spellbook ===

  DEFAULT_ATTACK_SPELL_TILES = {
    :spell_lightning => AttackSpellTile.new( 10, 1,  4),
    :spell_bigball   => AttackSpellTile.new( 11, 2,  9),
    :spell_coolcube  => AttackSpellTile.new( 12, 4, 20),
  }

  DEFAULT_OTHER_SPELL_TILES = {
    :spell_magic_map      => MagicMapSpellTile.new( 13, 1 ),
    :spell_heal           => HealSpellTile.new( 14, 2, 2 ),
    :spell_summon_mana    => SummonManaSpellTile.new( 15, 0, 3, 2 ),
    :spell_spy_eye        => SpyEyeSpellTile.new( 16, 1 ),
    # :spell_x2              => SpellTile.new( 18 ),
  }

end


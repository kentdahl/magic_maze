require 'test/unit'

require 'magicmaze/player'

class TestSpellBook < Test::Unit::TestCase
  include MagicMaze
  def setup
    @spellbook = Player::SpellBook.new
  end

  def test_lookup
    lightning = @spellbook.spell 
    assert_equal( DEFAULT_ATTACK_SPELL_TILES[:spell_lightning], lightning )
  end

  def test_loop
    orig_spell = @spellbook.spell( :primary )
    @spellbook.page_spell(:primary)
    spell = @spellbook.spell(:primary)
    assert_equal( DEFAULT_ATTACK_SPELL_TILES[:spell_bigball], spell)
    @spellbook.page_spell(:primary, -1)
    spell = @spellbook.spell(:primary)
    assert_equal( orig_spell, spell )
  end

end

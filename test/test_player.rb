require 'test/unit'

require 'magicmaze/spellbook'

class TestSpellBook < Test::Unit::TestCase
  include MagicMaze
  def setup
    @spellbook = SpellBook.new
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

  def test_secondary_loop
    orig_spell = @spellbook.spell( :secondary )
    assert_equal( DEFAULT_OTHER_SPELL_TILES[:spell_heal], orig_spell)

    @spellbook.page_spell(:secondary)
    spell = @spellbook.spell(:secondary)
    assert_equal( DEFAULT_OTHER_SPELL_TILES[:spell_summon_mana], spell)
    @spellbook.page_spell(:secondary, -1)
    spell = @spellbook.spell(:secondary)
    assert_equal( orig_spell, spell )
  end

  def test_secondary_spell_names

    secondary_spell_names = ::MagicMaze::SpellBook::SPELL_NAMES[:secondary]

    (1...secondary_spell_names.size).each do |index|
      @spellbook.page_spell(:secondary)
      spell = @spellbook.spell(:secondary)
      spell_name = secondary_spell_names[index]
      p spell_name
      p spell
      assert_equal( DEFAULT_OTHER_SPELL_TILES[ spell_name ], spell)
    end


  end



end

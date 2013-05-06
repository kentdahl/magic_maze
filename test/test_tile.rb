require 'test/unit'

require 'magicmaze/tile'
require 'magicmaze/spelltile'


class TestBackgroundTile < Test::Unit::TestCase
  def test_blocked
    t = MagicMaze::BackgroundTile.new( 5, true )
    assert( t.blocked? )
    t = MagicMaze::BackgroundTile.new( 6, false )
    assert( ! t.blocked? )
  end
end


class TestSpellTile < Test::Unit::TestCase

  class TestSpell < MagicMaze::SpellTile
    def do_magic
      @magic_done = true
      return @should_do_magic
    end
    attr_accessor :magic_done
    attr_accessor :should_do_magic
  end

  ##
  # Mock methods: Pretend to be the caster (Player)
  def have_mana?( cost )
    @requested_cost = cost
    return @have_mana
  end
  def add_mana( cost )
    @used_cost = -cost
  end


  def setup
    @mana_cost = 5
    @spell = TestSpell.new( 0, @mana_cost )
  end


  def test_spell 
    @have_mana = true
    @spell.should_do_magic = true
    @spell.cast_spell( self )
    assert_equal 5, @requested_cost
    assert_equal 5, @used_cost
    assert @spell.magic_done
  end

  def test_spell_fail_do_magic 
    @have_mana = true
    @spell.should_do_magic = false
    @spell.cast_spell( self )
    assert @spell.magic_done
    assert_equal 5, @requested_cost
    assert_equal nil, @used_cost
  end

  def test_spell_fail_have_mana 
    @have_mana = false
    @spell.should_do_magic = true
    @spell.cast_spell( self )
    assert ! @spell.magic_done
    assert_equal 5, @requested_cost
    assert_equal nil, @used_cost
  end

  def test_spell_fail_have_mana 
    @have_mana = false
    @spell.should_do_magic = true
    @spell.cast_spell( self )
    assert ! @spell.magic_done
    assert_equal 5, @requested_cost
    assert_equal nil, @used_cost
  end

end

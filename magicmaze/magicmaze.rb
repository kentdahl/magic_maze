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

require 'magicmaze/game'

# necessary for pthreads/sound problem?
require 'rbconfig'
if RUBY_PLATFORM =~ /linux/
  trap('INT','EXIT')
#  trap('EXIT','EXIT')
end

# Try to enable translations.
begin
  # raise LoadError # Testing fallback...
  require 'gettext'
rescue LoadError
  # Dummy fall-through to english.
  module GetText
    def bindtextdomain(s)
    end
    def _(s)
      s
    end
  end
end

# For translation...
include GetText
bindtextdomain("magicmaze")

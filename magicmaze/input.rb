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

module MagicMaze

  ##
  # module for handling input from the user.
  module Input


    ##
    # Callback for implementing states where 
    # keys can only be used to break out of a loop or similar
    #
    class BreakCallback
      def initialize( block )
        @block = block
      end
      def callback
        @block.call
      end
      alias :break :callback
      def self.make_control( key_mode = :break, &block )
        Control.new( self.new( block ), key_mode )
      end
    end
    
  end # Input

end # MagicMaze

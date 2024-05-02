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

  ################################################
  #
  class Graphics
    DEBUG = true

    MM_BASE_GFX_PATH  = 'data/gfx/'
    DEB_BASE_GFX_PATH = '/usr/share/magicmaze/gfx/'

    GFX_PATH = 'data/gfx/'
    SCREEN_IMAGES = {
      :titlescreen => 'title.png',
      :background  => 'background.png',
      :endscreen   => 'end.png',
    }

    SCALE_FACTOR = (self.const_defined?("OVERRIDE_GRAPHICS_SCALE_FACTOR") ? OVERRIDE_GRAPHICS_SCALE_FACTOR : 2)

    BACKGROUND_TILES_BEGIN = BackgroundTile::BACKGROUND_TILES_BEGIN

    COL_WHITE=10;   COL_RED = 20;   COL_GREEN = 30;  COL_BLUE = 40; 
    COL_YELLOW = 50;
    COL_DARKGRAY=3;    COL_GRAY=5;  COL_LIGHTGRAY=7;

    SPRITE_WIDTH = 32 * SCALE_FACTOR; SPRITE_HEIGHT = 32 * SCALE_FACTOR;

    # the *_AREA_MAP_* variables are map coordinate related, not screen coordinate.
    VIEW_AREA_MAP_WIDTH  = 7
    VIEW_AREA_MAP_HEIGHT = 7
    VIEW_AREA_MAP_WIDTH_CENTER  = VIEW_AREA_MAP_WIDTH  / 2
    VIEW_AREA_MAP_HEIGHT_CENTER = VIEW_AREA_MAP_HEIGHT / 2


    VIEW_AREA_UPPER_LEFT_X = 2 * SCALE_FACTOR
    VIEW_AREA_UPPER_LEFT_Y = 2 * SCALE_FACTOR

    # rectangles on the display. [startx, starty, width, height, colour]  
    FULLSCREEN          = [ 0, 0, 320, 240,0].collect{|i| i*SCALE_FACTOR}
    INVENTORY_RECTANGLE = [230, 16, 87,32, 0].collect{|i| i*SCALE_FACTOR} 
    LIFE_MANA_RECTANGLE = [230, 63, 87,16, 0].collect{|i| i*SCALE_FACTOR}
    SCORE_RECTANGLE     = [230+8, 93, 87-8,14, 0].collect{|i| i*SCALE_FACTOR}
    SPELL_RECTANGLE     = [230,126, 32,32, 0].collect{|i| i*SCALE_FACTOR} 
    ALT_SPELL_RECTANGLE = [285,126, 32,32, 0].collect{|i| i*SCALE_FACTOR} 
    MAZE_VIEW_RECTANGLE = [
      VIEW_AREA_UPPER_LEFT_X, VIEW_AREA_UPPER_LEFT_Y, 
      SPRITE_WIDTH*VIEW_AREA_MAP_WIDTH, SPRITE_HEIGHT*VIEW_AREA_MAP_HEIGHT, 0
    ] 


    PLAYER_SPRITE_POSITION = [
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_WIDTH_CENTER, 
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_HEIGHT_CENTER ]


    ##
    # Singleton graphics instance.
    def self.get_graphics(options={})
      @graphics_instance ||= MagicMaze::Graphics.new(options)
      @graphics_instance
    end

    def self.shutdown_graphics
      @graphics_instance.destroy
      @graphics_instance = nil
    end


  end # Graphics

end



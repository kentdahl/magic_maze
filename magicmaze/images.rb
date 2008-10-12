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

require 'sdl'

require 'magicmaze/tile'

module MagicMaze

  ################################################
  # Generic GFX stuff.
  # 
  module Images

    ##
    # Slow, but blocky and non-SGE scaling of image.
    #
    def linear_scale_image( source_image, sx,sy, scaled_image, factor = 1 )
      sw = scaled_image.w / factor
      sh = scaled_image.h / factor

      source_image.lock
      scaled_image.lock

      sh.times do |sdy|        
        sw.times do |sdx|
          pixel = source_image.get_pixel(sx+sdx, sy+sdy)
          scaled_image.fill_rect(sdx*factor, sdy*factor, factor, factor, pixel)
        end
      end

      source_image.unlock
      scaled_image.unlock

      scaled_image
    end


    ######################################################
    # general graphics methods

    ## put up a background screen
    def put_screen( screen, center = false, flip = true )
      @screen.fillRect(0,0,@xsize,@ysize,0)
      image = @background_images[ screen ]
      x,y=0,0
      if center
        x = (@xsize - image.w)/2
        y = (@ysize - image.h)/2        
      end
      @screen.put( image, x,y )
      @screen.flip if flip
    end

    def put_background( sprite, x, y )
      put_sprite( sprite, x, y )
    end

    def put_sprite( sprite, x, y )
      image = @sprite_images[sprite]
      @screen.put( image, x, y ) if image   
    end    

    def flip
      @screen.flip
    end

    def toogle_fullscreen
      @screen.toggle_fullscreen
    end

    def write_text( text, x, y, font = @font16 )
      font.drawSolidUTF8(@screen,text,x,y,255,255,255)
    end

    def write_smooth_text( text, x, y, font = @font16,r=255,g=255,b=255 )
      font.drawBlendedUTF8(@screen, text, x,y, r,g,b)
    end

    def set_palette( pal, start_color = 0 )
      pal ||= @sprite_palette
      @screen.set_palette( SDL::PHYSPAL, pal, start_color )
    end

    FADE_DURATION = 16

    def fade_out( tr = 0, tg = 0, tb = 0, fade_duration = FADE_DURATION )
      mypal = @sprite_palette.dup
      @old_palette = mypal
      range = fade_duration
      (0...range).each {|i|
	factor = (range-i).to_f / range
	set_palette( mypal.map {|r,g,b| 
		      [ ( r - tr ) * factor + tr,
			( g - tg ) * factor + tg, 
			( b - tb ) * factor + tb ]
		    } )
	yield i, range
      }
      @fade_color = [ tr, tg, tb ]
    end

    def fade_in( fade_duration = FADE_DURATION )
      mypal = @old_palette || @sprite_palette
      tr, tg, tb = *(@fade_color || [0,0,0])
      range = fade_duration
      (0..range).each {|i|
	factor = i.to_f / range
	set_palette( mypal.map {|r,g,b| 
		      [ ( r - tr ) * factor + tr,
			( g - tg ) * factor + tg, 
			( b - tb ) * factor + tb ]
		    } )
	yield i, range
      }
      set_palette( mypal )
    end

    def fade_in_and_out( sleep_ms = 500, &block )
      fade_in( &block )
      SDL.delay( sleep_ms )
      fade_out( &block )      
    end

    def clear_screen
      @screen.fillRect( 0, 0, @xsize, @ysize, 0 )
    end

  end # Images

end

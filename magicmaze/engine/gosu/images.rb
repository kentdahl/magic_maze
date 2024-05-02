############################################################
# Magic Maze - a simple and low-tech monster-bashing maze game.
# Copyright (C) 2004-2013 Kent Dahl
#
# This game is FREE as in both BEER and SPEECH. 
# It is available and can be distributed under the terms of 
# the GPL license (version 2) or alternatively 
# the dual-licensing terms of Ruby itself.
# Please see README.txt and COPYING_GPL.txt for details.
############################################################

require 'gosu'

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
      source_image
    end


    ######################################################
    # general graphics methods

    ## put up a background screen
    def put_screen( screen, center = false, flip = true )
      image = @background_images[ screen ]
      x,y=0,0
      if center
        x = (@xsize - image.width)/2
        y = (@ysize - image.height)/2        
      end
      @curr_bg = image
      @curr_bg.draw(x,y,0)
      screen
    end

    def put_background( sprite, x, y )
      put_sprite( sprite, x, y )
    end

    def put_sprite( sprite, x, y, layer = 1 )
      image = @sprite_images[sprite]
      image.draw(x, y, layer ) if image   
    end    

    def flip
      # @screen.flip
    end

    def toogle_fullscreen
      # @screen.toggle_fullscreen
    end

    def write_text( text, x, y, font = @font16 )
      begin
        font.drawSolidUTF8(@screen,text,x,y,255,255,255)
      rescue => err # Original Asus EEE distro fails here...
        write_smooth_text(text,x,y,font)
      end
    end

    def write_smooth_text( text, x, y, font = @font16,r=255,g=255,b=255 )
      puts "TODO: write: #{text}"
      #font.drawBlendedUTF8(@screen, text, x,y, r,g,b) # Failed for RubySDL2.0.1 and Ruby1.9.1-p1 on multiline strings.
    end

    def set_palette( pal, start_color = 0 )
      #pal ||= @sprite_palette
      #@screen.set_palette( SDL::PHYSPAL, pal, start_color )
    end

    FADE_DURATION = 16

    def fade_out( tr = 0, tg = 0, tb = 0, fade_duration = FADE_DURATION )
      return 
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
        yield i, range if block_given?
      }
      @fade_color = [ tr, tg, tb ]
    end

    def fade_in( fade_duration = FADE_DURATION )
      return 
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
        yield i, range if block_given?
      }
      set_palette( mypal )
    end

    def fade_in_and_out( sleep_ms = 500, &block )
      block.call
      fade_in {} #( &block )
      sleep_delay( sleep_ms )
      fade_out {} #( &block )      
    end

    def clear_screen
      # @screen.fillRect( 0, 0, @xsize, @ysize, 0 )
    end

    def sleep_delay( sleep_ms = 1 )
      return 
    end
    
    ##
    # Add delay after action to smooth ticks.
    # Don't delay if it took too long.
    # 
    def time_synchronized( game_delay = 50 )
      #time_start = SDL.get_ticks
      yield # Do actual work.
      #time_end = SDL.get_ticks
      #delay = game_delay + time_start - time_end
      # @delay_stats << delay # if debugging...
      #sleep_delay(delay) if delay > 0 
    end


  end # Images

end

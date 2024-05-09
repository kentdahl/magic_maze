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

require 'sdl2'

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
          pixel = source_image.pixel(sx+sdx, sy+sdy)
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
      @screen.clear
      @screen.fill_rect(SDL2::Rect[0,0,@xsize,@ysize])
      image = @background_images[ screen ]
      x,y=0,0
      if center
        x = (@xsize - image.w)/2
        y = (@ysize - image.h)/2        
      end
      @screen.copy( image, nil, SDL2::Rect[x,y,image.w, image.h] )
      self.flip if flip
    end

    def put_background( sprite, x, y )
      put_sprite( sprite, x, y )
    end

    def put_sprite( sprite, x, y )
      image = @sprite_images[sprite]
      @screen.copy( image, nil, SDL2::Rect[x, y, image.w, image.h] ) # if image   
    end    

    def flip
      @screen.present
    end

    def toogle_fullscreen
      fsmode = @window.fullscreen_mode
      if fsmode == 0 then
        @window.fullscreen_mode = ::SDL2::Window::Flags::FULLSCREEN
      else
        @window.fullscreen_mode = 0
      end
    end

    def write_text( text, x, y, font = @font16 )
      begin
        scribbles = font.render_solid(text, [0xFF, 0xFF, 0xFF])
        tribbles  = @screen.create_texture_from(scribbles)
        dims = font.size_text(text)
        @screen.copy(tribbles, nil, SDL2::Rect[x,y,dims.first,dims.last])
        # TODO: font.drawSolidUTF8(@screen,text,x,y,255,255,255)
      rescue SDL2::Error # Original Asus EEE distro fails here...
        write_smooth_text(text,x,y,font)
      end
    end

    def write_smooth_text( text, x, y, font = @font16,r=255,g=255,b=255 )
      # TODO: font.drawBlendedUTF8(@screen, text, x,y, r,g,b) # Failed for RubySDL2.0.1 and Ruby1.9.1-p1 on multiline strings.
      scribbles = font.render_blended(text, [r, g, b])
      tribbles  = @screen.create_texture_from(scribbles)
      dims = font.size_text(text)
      @screen.copy(tribbles, nil, SDL2::Rect[x,y,dims.first,dims.last])

    end

    def set_palette( pal, start_color = 0 )
      # pal ||= @sprite_palette
      # @screen.set_palette( SDL2::PHYSPAL, pal, start_color )
    end

    FADE_DURATION = 16

    def fade_out( tr = 0, tg = 0, tb = 0, fade_duration = FADE_DURATION, ms_delay = 10 )
      # TODO:
      range = fade_duration
      (0...range).each {|i|
        factor = (range-i).to_f / range
        @window.brightness = factor
        if block_given?
          yield i, range
        else
          sleep_delay(ms_delay)
        end
      }
      @window.brightness = 0.0
    end

    def fade_in( fade_duration = FADE_DURATION, ms_delay = 10 )
      # TODO:
      range = fade_duration
      (0..range).each {|i|
        factor = i.to_f / range
        @window.brightness = factor
        if block_given?
          yield i, range
        else
          sleep_delay(ms_delay)
        end
      }
      @window.brightness = 1.0
    end


    def old_fade_out( tr = 0, tg = 0, tb = 0, fade_duration = FADE_DURATION )
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

    def old_fade_in( fade_duration = FADE_DURATION )
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
      @screen.draw_color = [0,0,0]
      @screen.clear
      # @screen.fill_rect( SDL2::Rect.new(0, 0, @xsize, @ysize) )
    end

    def sleep_delay( sleep_ms = 1 )
      SDL2.delay( sleep_ms )
    end
    
    ##
    # Add delay after action to smooth ticks.
    # Don't delay if it took too long.
    # 
    def time_synchronized( game_delay = 50 )
      time_start = SDL2.get_ticks
      yield # Do actual work.
      time_end = SDL2.get_ticks
      delay = game_delay + time_start - time_end
      # @delay_stats << delay # if debugging...
      sleep_delay(delay) if delay > 0 
    end


  end # Images

end

require 'sdl'

require 'magicmaze/tile'

module MagicMaze

  ################################################
  # Generic GFX stuff.
  # 
  module Images

    def load_background_images
      @background_images = {}
      SCREEN_IMAGES.each{|key, filename|
        source_image = SDL::Surface.load( GFX_PATH+filename ) 
        if SCALE_FACTOR != 1 then
          scaled_image = SDL::Surface.new(SDL::SWSURFACE, 
                                        source_image.w * SCALE_FACTOR, 
                                        source_image.h * SCALE_FACTOR,
                                          @screen)
          scaled_image.set_palette( SDL::LOGPAL|SDL::PHYSPAL, 
                                    source_image.get_palette, 0 )
          linear_scale_image(source_image,0,0, scaled_image )
        else
          scaled_image = source_image
        end
        
        @background_images[key] = scaled_image
      }
    end

    ##
    # reads in the old sprites from the "undocumented" format I used.
    #
    def load_old_sprites
      sprite_images = []
      File.open( GFX_PATH+'sprites.dat', 'rb'){|file|
        # First 3*256 bytes is the palette, with values ranged (0...64).
        palette_data = file.read(768) 
        if palette_data.size == 768 then
          palette = (0..255).collect{|colour|
            data = palette_data[colour*3,3]
            [data[0], data[1], data[2]].collect{|i| i*255/63}
              #((i<<2) | 3) + 3 }
          }
        end

	@sprite_palette = palette

        # Loop over 1030 byte segments, which each is a sprite.
        begin
          sprite = SDL::Surface.new(SDL::HWSURFACE, # SDL::SRCCOLORKEY,
                                    SPRITE_WIDTH,SPRITE_HEIGHT,@screen)
          mode =  SDL::LOGPAL|SDL::PHYSPAL
          sprite.set_palette( mode, palette, 0 )
          @screen.set_palette(mode, palette, 0 )
          sprite_data = file.read(1030)
          if sprite_data && sprite_data.size==1030 then
            x = 0
            y = 0
            sprite.lock
            # The first six bytes is garbage?
            sprite_data[6,1024].each_byte{|pixel|
              sprite.put_pixel(x,y,pixel)
              x += 1 # *SCALE_FACTOR
              if x>31
                x = 0
                y += 1
              end              
            }
            sprite.unlock
            sprite.setColorKey( SDL::SRCCOLORKEY || SDL::RLEACCEL ,0)
            sprite_images << sprite.display_format
          end
        end while sprite_data
      }
      sprite_images
    end



    ##
    # Load sprites from a large bitmap. Easier to edit.
    #
    def load_new_sprites
      puts "Loading sprites..." if DEBUG
      sprite_images = []
      begin
	spritemap = SDL::Surface.load( GFX_PATH + 'sprites.pcx' ) 
      rescue
	return nil
      end

      palette = spritemap.get_palette

      lines = ( spritemap.h + 15 ) / 32 

      @screen.set_palette( SDL::LOGPAL|SDL::PHYSPAL, palette, 0 )


      (0...lines).each do|line|	
	(0...10).each do|column|
	  sprite = SDL::Surface.new(SDL::HWSURFACE, #|SDL::SRCCOLORKEY,
                                    SPRITE_WIDTH, SPRITE_HEIGHT, @screen)
          mode =  SDL::LOGPAL|SDL::PHYSPAL

	  x =  column * 32
	  y = line * 32
	  w = h = 32

	  sprite.set_palette( mode, palette, 0 )
	  sprite.setColorKey( SDL::SRCCOLORKEY || SDL::RLEACCEL ,0)
          sprite.fillRect(0,0,SPRITE_WIDTH,SPRITE_HEIGHT,3)

          if SCALE_FACTOR == 1 then
            SDL.blitSurface(spritemap,x,y,w,h,sprite, 0,0 )
          else
            linear_scale_image(spritemap,x,y, sprite )
          end

	  sprite.set_palette( mode, palette, 0 )
	  sprite.setColorKey( SDL::SRCCOLORKEY || SDL::RLEACCEL ,0)

	  sprite_images << sprite.display_format
	end
      end

      @sprite_palette = palette 
      puts "Sprites loaded: #{sprite_images.size}." if DEBUG

      sprite_images
    end



    ##
    # save sprites out to bitmap
    #
    def save_old_sprites( filename = "tmpgfx" )
      height = ( (@sprite_images.size / 10) + 1 ) * 32

      spritemap = SDL::Surface.new( SDL::SRCCOLORKEY, @xsize, height, @screen )
      spritemap.set_palette( SDL::LOGPAL, @sprite_palette, 0 )

      @sprite_images.each_with_index do|sprite, index|
	y = (index / 10)  * 32
	x = (index % 10 ) * 32
	spritemap.put( sprite, x, y )
      end

      spritemap.save_bmp( filename + ".bmp" )      
    end

  end # Images

end

require 'sdl'
module MagicMaze

  ################################################
  #
  class Graphics
    GFX_PATH = 'data/gfx/'
    SCREEN_IMAGES = {
      :titlescreen => 'title.pcx',
      :background  => 'background.pcx',
      :endscreen   => 'end.pcx',
    }

    BACKGROUND_TILES_BEGIN = BackgroundTile::BACKGROUND_TILES_BEGIN

    COL_RED = 20;   COL_GREEN = 30;  COL_BLUE = 40;

    SPRITE_WIDTH = 32; SPRITE_HEIGHT = 32;

    # the *_AREA_MAP_* variables are map coordinate related, not screen coordinate.
    VIEW_AREA_MAP_WIDTH  = 7
    VIEW_AREA_MAP_HEIGHT = 7
    VIEW_AREA_MAP_WIDTH_CENTER  = VIEW_AREA_MAP_WIDTH  / 2
    VIEW_AREA_MAP_HEIGHT_CENTER = VIEW_AREA_MAP_HEIGHT / 2


    VIEW_AREA_UPPER_LEFT_X = 2
    VIEW_AREA_UPPER_LEFT_Y = 2

    # rectangles on the display. [startx, starty, width, height, colour]  
    INVENTORY_RECTANGLE = [230, 16, 87,32, 0]  # 316,47]
    LIFE_MANA_RECTANGLE = [230, 63, 87,16, 0]  # 316,78]
    SCORE_RECTANGLE     = [230, 93, 87,14, 0] # 316,106]
    SPELL_RECTANGLE     = [230,126, 32,32, 0] #261,157]
    ALT_SPELL_RECTANGLE = [285,126, 32,32, 0] #316,157]
    MAZE_VIEW_RECTANGLE = [
      VIEW_AREA_UPPER_LEFT_X, VIEW_AREA_UPPER_LEFT_Y, 
      SPRITE_WIDTH*VIEW_AREA_MAP_WIDTH, SPRITE_HEIGHT*VIEW_AREA_MAP_HEIGHT, 0
    ] 


    PLAYER_SPRITE_POSITION = [
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_WIDTH_CENTER, 
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_HEIGHT_CENTER ]


    def initialize
      @xsize = 320
      @ysize = 240
      @bpp = 8 # 16 wont work
      SDL.init( SDL::INIT_VIDEO )
      SDL::Mouse.hide
      SDL::WM.set_caption( "Magic Maze","" )
      SDL::WM.icon=( SDL::Surface.load("data/gfx/icon.png") )

      @screen = SDL::setVideoMode(@xsize,@ysize, @bpp,
                                  #SDL::FULLSCREEN + 
                                  SDL::HWSURFACE +
                                  SDL::DOUBLEBUF
                                  ) #& SDL::SWSURFACE)
      @background_images = {}
      SCREEN_IMAGES.each{|key, filename|
        @background_images[key] = 
          SDL::Surface.load( GFX_PATH+filename ) 
      }
      #sprite_images = SDL::Surface.load( GFX_PATH+'sprites.pcx' )
      @sprite_images = load_old_sprites

      ## Fonts
      SDL::TTF.init
      # Free font found at: http://www.squaregear.net/fonts/ 
      @font = SDL::TTF.open( "data/gfx/fraktmod.ttf", 16 )
    end


    # reads in the old sprites from the "undocumented" format I used
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
                                    32,32,@screen)
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
              x += 1
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

    def write_text( text, x, y )
      @font.drawSolidUTF8(@screen,text,x,y,255,255,255)
    end


    #################################################
    # View specific methods


    def write_score( score )
      text = sprintf "%09d", score
      rect = SCORE_RECTANGLE
      @screen.fillRect(*rect) 
      write_text( text, rect[0]+4, rect[1]-3 ) #216,75)
    end

    def show_message( text )
      rect = MAZE_VIEW_RECTANGLE
      @screen.fillRect(*rect)
      write_text( text, rect[0]+4, rect[1]-3 ) 
      @screen.flip
    end
    
    ##
    # assumes life and mana are in range (0..100)
    def update_life_and_mana( life, mana )
      rect = LIFE_MANA_RECTANGLE
      @screen.fillRect(*rect) 
      @screen.fillRect(rect[0], rect[1], 
                       rect[2]*life/100, rect[3]/2, 
                       COL_RED)  if life.between?(0,100)
      @screen.fillRect(rect[0], rect[1]+rect[3]/2, 
                       rect[2]*mana/100, rect[3]/2,
                       COL_BLUE) if mana.between?(0,100)      
    end

    def update_inventory( inventory )
      rect = INVENTORY_RECTANGLE
      @screen.fillRect(*rect) 
      currx = rect.first
      curry = rect[1]
      stepx = SPRITE_WIDTH / 4
      inventory.each{|obj|
        put_sprite(obj, currx, curry )
        currx += stepx
      }
    end

    def update_spells( primary, secondary )
      rect1 = SPELL_RECTANGLE
      rect2 = ALT_SPELL_RECTANGLE
      @screen.fillRect( *rect1 )
      put_sprite( primary, *rect1[0,2]) 
      @screen.fillRect( *rect2 )
      put_sprite( secondary, *rect2[0,2]) 
    end

    def update_player( player_sprite )
      put_sprite(player_sprite, *PLAYER_SPRITE_POSITION )
    end



    ####################################
    # Experimental view updating trying 
    # to refactor and separate view logic
    # from the GameLoop as much as possible.

    def update_view_rows( center_row )
      @curr_view_y = MAZE_VIEW_RECTANGLE[1]
      VIEW_AREA_MAP_HEIGHT.times{|i| 
        yield i+center_row-VIEW_AREA_MAP_HEIGHT_CENTER
        @curr_view_y += SPRITE_HEIGHT
      }
    end
    def update_view_columns( center_column )
      @curr_view_x = MAZE_VIEW_RECTANGLE[0]
      VIEW_AREA_MAP_WIDTH.times{|i|
        yield i+center_column-VIEW_AREA_MAP_WIDTH_CENTER
        @curr_view_x += SPRITE_WIDTH
      }
    end
    def update_view_background_block( sprite_id )
      put_background( sprite_id, @curr_view_x, @curr_view_y )
    end
    def update_view_block( sprite_id )
      put_sprite( sprite_id, @curr_view_x, @curr_view_y )
    end


    ####################################
    #

    def set_palette( pal, start_color = 0 )
      @screen.set_palette( SDL::PHYSPAL|SDL::LOGPAL, pal, start_color )
    end

    def fade_out( tr = 0, tg = 0, tb = 0 )
      mypal = @sprite_palette.dup
      @old_palette = mypal
      range = 127
      (0..range).each {|i|
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

    def fade_in
      mypal = @old_palette || @sprite_palette
      tr, tg, tb = *(@fade_color || [0,0,0])
      range = 127
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




  end # Graphics

end

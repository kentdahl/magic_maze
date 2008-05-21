require 'sdl'

require 'magicmaze/tile'

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

    SCALE_FACTOR = 1

    BACKGROUND_TILES_BEGIN = BackgroundTile::BACKGROUND_TILES_BEGIN

    COL_WHITE=10;   COL_RED = 20;   COL_GREEN = 30;  COL_BLUE = 40; 
    COL_YELLOW = 50;

    SPRITE_WIDTH = 32 * SCALE_FACTOR; SPRITE_HEIGHT = 32 * SCALE_FACTOR;

    # the *_AREA_MAP_* variables are map coordinate related, not screen coordinate.
    VIEW_AREA_MAP_WIDTH  = 7
    VIEW_AREA_MAP_HEIGHT = 7
    VIEW_AREA_MAP_WIDTH_CENTER  = VIEW_AREA_MAP_WIDTH  / 2
    VIEW_AREA_MAP_HEIGHT_CENTER = VIEW_AREA_MAP_HEIGHT / 2


    VIEW_AREA_UPPER_LEFT_X = 2
    VIEW_AREA_UPPER_LEFT_Y = 2

    # rectangles on the display. [startx, starty, width, height, colour]  
    FULLSCREEN          = [ 0, 0, 320, 240,0].collect{|i| i*SCALE_FACTOR}
    INVENTORY_RECTANGLE = [230, 16, 87,32, 0].collect{|i| i*SCALE_FACTOR} 
    LIFE_MANA_RECTANGLE = [230, 63, 87,16, 0].collect{|i| i*SCALE_FACTOR}
    SCORE_RECTANGLE     = [230, 93, 87,14, 0].collect{|i| i*SCALE_FACTOR}
    SPELL_RECTANGLE     = [230,126, 32,32, 0].collect{|i| i*SCALE_FACTOR} 
    ALT_SPELL_RECTANGLE = [285,126, 32,32, 0].collect{|i| i*SCALE_FACTOR} 
    MAZE_VIEW_RECTANGLE = [
      VIEW_AREA_UPPER_LEFT_X, VIEW_AREA_UPPER_LEFT_Y, 
      SPRITE_WIDTH*VIEW_AREA_MAP_WIDTH, SPRITE_HEIGHT*VIEW_AREA_MAP_HEIGHT, 0
    ] 


    PLAYER_SPRITE_POSITION = [
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_WIDTH_CENTER, 
      2 + SPRITE_WIDTH * VIEW_AREA_MAP_HEIGHT_CENTER ]


    def initialize
      @xsize = FULLSCREEN[2]
      @ysize = FULLSCREEN[3]
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
        source_image = SDL::Surface.load( GFX_PATH+filename ) 
        if SCALE_FACTOR != 1 then
          scaled_image = SDL::Surface.new(SDL::SWSURFACE, 
                                        source_image.w * SCALE_FACTOR, 
                                        source_image.h * SCALE_FACTOR,
                                          @screen)
          scaled_image.set_palette( SDL::LOGPAL|SDL::PHYSPAL, 
                                    source_image.get_palette, 0 )
          scaled_image.fillRect(0,0,5,5,555)
        SDL.transform(source_image, scaled_image, 0,
                      SCALE_FACTOR, SCALE_FACTOR, 0,0, 0,0, 1)
        else
          scaled_image = source_image
        end
        
        @background_images[key] = scaled_image
      }
      #sprite_images = SDL::Surface.load( GFX_PATH+'sprites.pcx' )
      @sprite_images = load_new_sprites || load_old_sprites 

      ## Fonts
      SDL::TTF.init
      # Free font found at: http://www.squaregear.net/fonts/ 
      @font16 = SDL::TTF.open( "data/gfx/fraktmod.ttf", 16 * SCALE_FACTOR )
      @font32 = SDL::TTF.open( "data/gfx/fraktmod.ttf", 32 * SCALE_FACTOR )
      @font = @font16
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
              x += 1*SCALE_FACTOR
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
      sprite_images = []
      begin
	spritemap = SDL::Surface.load( GFX_PATH + 'sprites.pcx' ) 
      rescue
	return nil
      end

      palette = spritemap.get_palette

      lines = ( spritemap.h / 32 + 1)

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

          if SCALE_FACTOR == 1 then
            SDL.blitSurface(spritemap,x,y,w,h,sprite, 0,0 )
          else
            SDL.transform(spritemap,sprite,0,
                          SCALE_FACTOR,SCALE_FACTOR, x,y, 0,0,1)
          end

	  sprite_images << sprite.display_format
	end
      end

      @sprite_palette = palette 

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

    def write_smooth_text( text, x, y, font = @font16 )
      font.drawBlendedUTF8(@screen,text,x,y,255,255,255)
    end


    #################################################
    # View specific methods


    def write_score( score )
      text = sprintf "%09d", score
      rect = SCORE_RECTANGLE
      @screen.fillRect(*rect) 
      write_text( text, rect[0]+4, rect[1]-3 ) 
    end


    ##
    # Show a single line message centered in the 
    # maze view area.
    #
    def show_message( text, flip = true )
      rect = MAZE_VIEW_RECTANGLE
      @screen.fillRect(*rect)

      tw, th = @font32.text_size( text )

      x = rect[0] 
      y = rect[1]
      w = rect[2] 
      h = rect[3] 
      
      write_smooth_text(text, 
		 x + (w-tw)/2,
		 y + (h-th)/2, 
		 @font32 ) 
      @screen.flip if flip
    end

    ##
    # Show a multi-line message centered in the
    # maze view area.
    def show_long_message( text, flip = true, fullscreen = false )
      rect = ( fullscreen ? FULLSCREEN : MAZE_VIEW_RECTANGLE)
      @screen.fillRect(*rect)

      gth = 0
      lines = text.split("\n").collect do |line| 
	tw, th = @font32.text_size( line ) 
	gth += th
	[ line, tw, th ]
      end

      x = rect[0] 
      y = rect[1]
      w = rect[2] 
      h = rect[3] 

      y_offset = y + (h-gth)/2

      lines.each do |line, tw, th|
	write_smooth_text(line, 
			  x + (w-tw)/2,
			  y_offset, 
			  @font32 )
	y_offset += th
      end

      @screen.flip if flip
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
      pal ||= @sprite_palette
      @screen.set_palette( SDL::PHYSPAL, pal, start_color )
    end

    def fade_out( tr = 0, tg = 0, tb = 0 )
      mypal = @sprite_palette.dup
      @old_palette = mypal
      range = 63 # 127
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
      range = 63 # 127
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

    def fade_in_and_out( sleep_ms = 1000, &block )
      fade_in( &block )
      SDL.delay( sleep_ms )
      fade_out( &block )      
    end

    def clear_screen
      @screen.fillRect( 0, 0, @xsize, @ysize, 0 )
    end

    ####################################
    #
    def show_help
      clear_screen

      lines = [
	'  ---++* Magic Maze Help *++---',
	'Arrow keys to move the wizard.',
	'Ctrl :-  Cast attack spell',
	'Alt :-  Cast secondary spell',
	'X / Z :- Toggle attack spell',
	'A / S :- Toggle secondary spell',
	'',
	'Esc / Q :- Quit playing',
	'F9 / R :- Restart level',
	# '[F4]: Load game    [F5]: Save game',
	# '[S]: Sound on/off',
	'PgUp / PgDn :- Tune Volume',
	'Plus / Minus :- Tune Speed (on keypad)',
      ]
      
      y_offset = 0
      font = @font16
      lines.each{|line|
	write_smooth_text( line, 5, y_offset, font )
	y_offset+= font.height
      }
      
      flip
    end

    ####################################
    #
    def draw_map( player )
      map = player.location.map

      rect = MAZE_VIEW_RECTANGLE
      @screen.fillRect(*rect)

      ox = rect[0] + (rect[2] - map.max_x - 2 )/2
      oy = rect[1] + (rect[3] - map.max_y - 2 )/2

      @screen.lock

      # @screen.draw_rect( ox-1, oy-1, ox+map.max_x+1, oy+map.max_y+1, COL_WHITE )
      map.iterate_all_cells(1) do |x,y, background, object, entity, spiritual|
	col = nil
	col = COL_WHITE   if background.blocked? 
	col = COL_YELLOW  if entity.kind_of?( DoorTile )
	col = COL_RED     if entity.kind_of?( Monster )
	if col
	  @screen.put_pixel( x + ox, y + oy, col )
	end	
      end

      @screen.put_pixel( ox + player.location.x, oy + player.location.y, COL_BLUE )

      @screen.unlock

      @screen.flip
    end


    ##
    # Prepare a large sprite containing the scrolltext
    #
    def prepare_scrolltext( text )
      font = @font32
      textsize = font.text_size( text )

      @scrolltext = SDL::Surface.new(SDL::HWSURFACE, #|SDL::SRCCOLORKEY,
                                    textsize.first, textsize.last, @screen)

      @scrolltext.set_palette( SDL::LOGPAL|SDL::PHYSPAL, @sprite_palette, 0 )
      @scrolltext.setColorKey( SDL::SRCCOLORKEY || SDL::RLEACCEL ,0)


      font.drawBlendedUTF8( @scrolltext, text, 0, 0,  255, 255, 255 )
      @scrolltext_index = - @xsize
    end


    ##
    # Update the scrolltext area at the bottom of the screen.
    #
    def update_scrolltext
      
      @screen.fillRect( 0, 200, @xsize, 40, 0 )

      SDL.blit_surface( @scrolltext, 
                       @scrolltext_index, 0, @xsize, @scrolltext.h,
                       @screen, 0, 200 )

      @scrolltext_index += 1

      if @scrolltext_index > @scrolltext.w + @xsize
        @scrolltext_index = - @xsize
      end

    end


    def setup_rotating_palette( range, screen = nil )
      pal = @sprite_palette
      if screen
        pal = @background_images[ screen ].get_palette
      end
      @rotating_palette = pal[ range ]
      @rotating_palette_range = range
    end

    ##
    #
    def rotate_palette
      pal = @rotating_palette 
      col = pal.shift
      pal.push col

      @screen.set_palette( SDL::PHYSPAL|SDL::LOGPAL, pal, @rotating_palette_range.first )
    end



  end # Graphics

end



# For testing
if $0 == __FILE__
  g = MagicMaze::Graphics.new

  command = ARGV.first

  case command
  when 'save_sprites'
    g.save_old_sprites 
  when 'load_spritemap'
    g.load_new_sprites
    pal = g.instance_eval{ @sprite_palette }
    p pal.class, pal.size
    pal.each{|line|
      puts
      line.each{|i| printf( "%02x ", i) if i.kind_of?(Numeric) }
    }
  end

end

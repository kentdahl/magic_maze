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

require 'magicmaze/images'
require 'magicmaze/tile'

module MagicMaze

  ################################################
  #
  class Graphics
    include Images # Generic GFX.
    DEBUG = true

    GFX_PATH = 'data/gfx/'
    SCREEN_IMAGES = {
      :titlescreen => 'title.pcx',
      :background  => 'background.pcx',
      :endscreen   => 'end.pcx',
    }

    SCALE_FACTOR = (self.constants.include?("OVERRIDE_GRAPHICS_SCALE_FACTOR") ? OVERRIDE_GRAPHICS_SCALE_FACTOR : 2)

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

    def initialize(options={})
      puts "Starting Magic Maze..."
      screen_init(options)
      early_progress
      font_init

      @progress_msg = _("Summoning") + "\n."
      early_progress

      load_background_images

      @progress_msg = _("Magic Maze") + "\n."
      early_progress

      @sprite_images = load_new_sprites || load_old_sprites 

      # show_message("Enter!")
      
      # Cached values for what is already drawn.
      @cached_drawing = Hash.new
      @delay_stats = Array.new

      puts "Graphics initialized." if DEBUG
    end

    def destroy
      if @delay_stats && @delay_stats.size.nonzero? then
	puts "Delay average: " + 
	  (@delay_stats.inject(0.0){|i,j|i+j}/@delay_stats.size).to_s
	puts "Delay min/max: " + 
	  @delay_stats.min.to_s + " / " + @delay_stats.max.to_s
      end
      SDL.quit
    end

    def screen_init(options)
      puts "Setting up graphics..." if DEBUG
      @xsize = FULLSCREEN[2]
      @ysize = FULLSCREEN[3]
      @bpp = 8 # 16 wont work
      SDL.init( SDL::INIT_VIDEO )
      SDL::Mouse.hide
      SDL::WM.set_caption( _("Magic Maze"),"" )
      # SDL::WM.icon=( SDL::Surface.load("data/gfx/icon.png") )

      screen_mode = SDL::HWSURFACE + SDL::DOUBLEBUF
      screen_mode += SDL::FULLSCREEN if options[:fullscreen] 

      @screen = SDL::setVideoMode(@xsize,@ysize, @bpp, screen_mode)
      early_progress

      SDL::WM.icon=( SDL::Surface.load("data/gfx/icon.png") )
      early_progress
      
      unless @screen.respond_to? :draw_rect then
	def @screen.draw_rect(x,y,w,h,c)
	  # Workaround for older Ruby/SDL...
	  fill_rect(x,y,   w,1, c)
	  fill_rect(x,y,   1,h, c)
	  fill_rect(x,y+h, w,1, c)
	  fill_rect(x+w,y, 1,h, c)
	end
      end
    end


    # Simple progress indication before we can write etc to screen.
    def early_progress(progress=nil, flip=true, clear=true)
      @progress = progress || (@progress||0)+1
      w = SCALE_FACTOR * (64 - @progress*8)
      c = 255 - (@progress**2)
      clear_screen if clear
      @screen.fill_rect(@xsize-w,0, w,@ysize,
			@screen.map_rgb(c,c,c))
      show_long_message(@progress_msg) if @progress_msg
      @screen.flip if flip
    end



    def font_init
      ## Fonts
      SDL::TTF.init
      # Free font found at: http://www.squaregear.net/fonts/ 
      fontfile = "data/gfx/fraktmod.ttf"
      fontsize = [16, 32]
      tries = 0
      begin
	@font16 = SDL::TTF.open( fontfile, fontsize.first * SCALE_FACTOR )
	@font32 = SDL::TTF.open( fontfile, fontsize.last  * SCALE_FACTOR )
      rescue SDL::Error => err
	# Debian font
	fontfile = "/usr/share/fonts/truetype/Isabella.ttf"
	fontsize = [12, 28]
	if tries < 1 then 
	  tries += 1 # to avoid loop.
	  retry 
	else 
	  raise err 
	end
      end
      @font = @font16
    end

    def load_background_images
      @background_images = {}
      SCREEN_IMAGES.each{|key, filename|
        source_image = SDL::Surface.load( GFX_PATH+filename ) 
	@progress_msg += "." ; early_progress
        if SCALE_FACTOR != 1 then
          scaled_image = SDL::Surface.new(SDL::SWSURFACE, 
                                        source_image.w * SCALE_FACTOR, 
                                        source_image.h * SCALE_FACTOR,
                                          @screen)
          scaled_image.set_palette( SDL::LOGPAL|SDL::PHYSPAL, 
                                    source_image.get_palette, 0 )
          linear_scale_image(source_image,0,0, scaled_image, SCALE_FACTOR )
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
	@progress_msg += "." ; early_progress
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
            linear_scale_image(spritemap,x,y, sprite, SCALE_FACTOR )
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



    #################################################
    # View specific methods


    def write_score( score )
      return if cached_drawing_valid?(:score, score )

      text = sprintf "%9d", score   # fails on EeePC
      # text = sprintf "%09d", score # old safe one.
      rect = SCORE_RECTANGLE
      @screen.fillRect(*rect) 
      write_text( text, rect[0]+2*SCALE_FACTOR, rect[1]-2*SCALE_FACTOR ) 
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

    def cached_drawing_valid?(symbol, value)
      return true if value == @cached_drawing[symbol]
      @cached_drawing[symbol] = value
      false
    end

    
    ##
    # assumes life and mana are in range (0..100)
    def update_life_and_mana( life, mana )
      return if cached_drawing_valid?(:life_and_mana, [life, mana] )

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
      return if cached_drawing_valid?(:inventory, inventory )

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
      return if cached_drawing_valid?(:spells, [primary, secondary] )

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
    def draw_map( player, line_by_line = true )
      map = player.location.map

      rect = MAZE_VIEW_RECTANGLE
      @screen.fillRect(*rect)
      
      if line_by_line then
	@screen.flip 
	@screen.fillRect(*rect)
      end

      map_zoom_factor = 4

      map_block_size = SPRITE_WIDTH / map_zoom_factor
      map_height = VIEW_AREA_MAP_HEIGHT * map_zoom_factor
      map_width  = VIEW_AREA_MAP_WIDTH  * map_zoom_factor

      (0...map_height).each do |ay|
        my = ay + player.location.y - map_height/2
        draw_y = rect[1] + ay*map_block_size

        (0...map_width).each do |ax|

          mx = ax + player.location.x - map_width/2

          col = nil
          map.all_tiles_at( mx, my ) do |background, o, entity, s|
            col = nil
            col = COL_LIGHTGRAY   if background.blocked? 
            col = COL_YELLOW      if entity.kind_of?( DoorTile )
            col = COL_RED         if entity.kind_of?( Monster )
            col = COL_BLUE        if entity.kind_of?( Player )
          end
          if col then
            @screen.fill_rect(rect[0] + ax*map_block_size,
                              draw_y,
                              map_block_size,
                              map_block_size,
                              col)
          end	

        end

	# The center.
	@screen.draw_rect(rect[0] + map_width/2  * map_block_size,
			  rect[1] + map_height/2 * map_block_size,
			  map_block_size,
			  map_block_size,
			  COL_WHITE)

        flip if line_by_line

      end

    end



    ##
    # Helper for doing gradual buildup of image.
    # Draws the same thing twice, once for immediate viewing,
    # and on the offscreen buffer for next round.
    #
    def draw_immediately_twice
      yield
      @screen.flip
      yield
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
      
      @screen.fillRect( 0, 200 * SCALE_FACTOR, @xsize, 40 * SCALE_FACTOR, 0 )

      SDL.blit_surface( @scrolltext, 
                       @scrolltext_index, 0, @xsize, @scrolltext.h,
                       @screen, 0, 200 * SCALE_FACTOR )

      @scrolltext_index += 1 * SCALE_FACTOR

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
    def rotate_palette # _ENABLED
      # DISABLED
    end
    def rotate_palette_DISABLED
      pal = @rotating_palette 
      col = pal.shift
      pal.push col

      @screen.set_palette( SDL::PHYSPAL|SDL::LOGPAL, pal, @rotating_palette_range.first )
    end

    ##
    # Prepare menu for rendering.
    #
    def setup_menu( entries, chosen = nil)
      @menu_items = entries

      max_width = 0
      total_height = 0
      font = @font32
      @menu_items.each do |text|
	tw, th = font.text_size( text )
	max_width = [max_width,tw+16*SCALE_FACTOR].max
	total_height += th + 4*SCALE_FACTOR
      end
      @menu_width = max_width
      @menu_chosen_item = chosen || @menu_items.first
      
      # Truncate if the items can fit on screen.
      scr_height = 200 * SCALE_FACTOR
      if total_height > scr_height then
	@menu_height = scr_height
	@menu_truncate_size = (@menu_items.size * scr_height / (total_height)).to_i
      else
	@menu_height = total_height
	@menu_truncate_size = false 
      end
    end

    ##
    # This does a generic menu event loop
    #
    def choose_from_menu( menu_items = %w{OK Cancel}, input = nil )
      setup_menu(menu_items)
      begin
	draw_menu
	menu_event = input ? input.get_menu_item_navigation_event : yield
	if [:previous_menu_item, :next_menu_item].include?(menu_event) then
	  self.send(menu_event)
	end
      end until [:exit_menu, :select_menu_item].include?(menu_event)
      erase_menu
      if menu_event == :select_menu_item then
	return menu_chosen_item
      else
	return false
      end
    end


    ##
    # Draw an updated menu.
    def draw_menu
      topx = 160 * SCALE_FACTOR - @menu_width  / (2)
      topy = 120 * SCALE_FACTOR - @menu_height / (2)

      #TODO: Save the old background.

      # Handle the case of truncated menu. Not too nice.
      if @menu_truncate_size then
	chosen_index = @menu_items.index(@menu_chosen_item)
	if chosen_index then
	  half_trunc = @menu_truncate_size / 2
	  first_item = [chosen_index-half_trunc, 0].max
	  if first_item.zero?
	    half_trunc += half_trunc - chosen_index
	  end
	  last_item  = [chosen_index+half_trunc, @menu_items.size].min

	  curr_menu_items = @menu_items[first_item..last_item]
	else
	  curr_menu_items = @menu_items[0..@menu_truncate_size]
	end
      else
	curr_menu_items = @menu_items
      end

      @screen.fillRect( topx, topy, @menu_width,@menu_height,0 )
      @screen.draw_rect( topx, topy, @menu_width,@menu_height, COL_GRAY )
      y_offset = topy
      font = @font32
      curr_menu_items.each do |text|
	tw, th = font.text_size( text )
	color_intensity = 127
	if text == @menu_chosen_item then
	  rect = [ 
	    topx + 4*SCALE_FACTOR, 
	    y_offset + 4*SCALE_FACTOR,
	    @menu_width - 8*SCALE_FACTOR, 
	    font.height - 4*SCALE_FACTOR,
	    COL_WHITE
	  ]
	  @screen.draw_rect( *rect )
	  color_intensity = 255
	end
	write_smooth_text(text, 
			  topx + (@menu_width-tw)/2, 
			  y_offset + 2*SCALE_FACTOR, 
			  font, *[color_intensity]*3 )
	y_offset+= font.height + 4*SCALE_FACTOR
      end
      flip
    end

    attr_reader :menu_chosen_item

    def previous_menu_item
      @menu_chosen_item = 
	@menu_items[@menu_items.index(@menu_chosen_item)-1] ||
	@menu_items.last
    end

    def next_menu_item
      @menu_chosen_item = 
	@menu_items[@menu_items.index(@menu_chosen_item)+1] ||
	@menu_items.first
    end


    ##
    # Erase the menu.
    def erase_menu
      # TODO: Restore background
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

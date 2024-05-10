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

require 'magicmaze/images'
require 'magicmaze/tile'

module MagicMaze

  ################################################
  #
  class Graphics
    include Images # Generic GFX.

    attr_reader :scale_factor

    def initialize(options={})
      puts "Starting Magic Maze..."
      @options = options
      screen_init(options)
      early_progress
      font_init

      @progress_msg = _("Summoning") + "\n."
      early_progress

      load_background_images

      @progress_msg = _("Magic Maze") + "\n."
      early_progress

      @sprite_images = load_new_sprites || load_old_sprites 

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
      @window.destroy ; @window = nil
      # SDL2.quit
    end

    def screen_init(options)
      puts "Setting up graphics..." if DEBUG

      @scale_factor ||= options[:scale] || SCALE_FACTOR
      @screen_scale_factor ||= @scale_factor

      @xsize = FULLSCREEN[2] * @screen_scale_factor
      @ysize = FULLSCREEN[3] * @screen_scale_factor

      SDL2.init( SDL2::INIT_VIDEO )
      SDL2::Mouse::Cursor.hide

      window_flags  = SDL2::Window::Flags::SHOWN
      window_flags |= SDL2::Window::Flags::FULLSCREEN if options[:fullscreen] 

      @window_pos_x = @window_pos_y = SDL2::Window::POS_CENTERED

      @window = SDL2::Window.create(_("Magic Maze"),
          @window_pos_x, @window_pos_y,
          @xsize, @ysize,
          window_flags)
      @window.icon = SDL2::Surface.load(gfx_path_to("icon.png"))

      @screen = @window.create_renderer(-1, 0)

      if self.scale_factor > 1
        @screen.scale = [@scale_factor, @scale_factor]
        @screen_scale_factor = @scale_factor
        # Leave the scaling to the screen renderer.
        @scale_factor = 1
      end


      early_progress

    end


    def screen_fill_rect(x,y,w,h,col=nil)
      with_draw_color(col) do
        @screen.fill_rect(SDL2::Rect[x,y,w,h])
      end
    end

    def screen_draw_rect(x,y,w,h,col=nil)
      with_draw_color(col) do
        @screen.draw_rect(SDL2::Rect[x,y,w,h])
      end
    end

    def with_draw_color(col = nil)
      if col
        oldcol = @screen.draw_color
        if col.is_a?(Numeric)
          newcol = COLOR_MAP[col]
          newcol ||= [col, col / 4 , col / 2]
        end
        @screen.draw_color = newcol || col
      end

      result = yield

      if col
        @screen.draw_color = oldcol
      end

      return result
    end

    # Simple progress indication before we can write etc to screen.
    def early_progress(progress=nil, flip=true, clear=true)
      @progress = progress || (@progress||0)+1
      w = self.scale_factor * (64 - @progress*8)
      c = 255 - (@progress**2)
      clear_screen if clear

      @screen.draw_color = [c,c,c]
      screen_fill_rect( @xsize-w,0, w,@ysize )
      show_long_message(@progress_msg) if @progress_msg
      self.flip if flip
    end



    def font_init
      ## Fonts
      SDL2::TTF.init
      # Free font found at: http://www.squaregear.net/fonts/ 
      fontfile = gfx_path_to("fraktmod.ttf")
      fontsize = [16, 24, 32]
      
      alternate_fonts = [
        gfx_path_to("Isabella.ttf"),
        # gfx_path_to("fraktmod.ttf"),
        "/usr/share/fonts/truetype/isabella/Isabella.ttf",
        "/usr/share/fonts/truetype/ttf-isabella/Isabella.ttf",
        "/usr/share/fonts/truetype/Isabella.ttf"
      ]
      
      begin
        @font16 = SDL2::TTF.open( fontfile, fontsize.first * self.scale_factor )
        @font24 = SDL2::TTF.open( fontfile, fontsize[1]    * self.scale_factor )
        @font32 = SDL2::TTF.open( fontfile, fontsize.last  * self.scale_factor )
      rescue SDL2::Error => err
        # Debian font
        fontfile = alternate_fonts.shift
        fontsize = [12, 16, 28]
        if fontfile then 
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
        source_image = SDL2::Surface.load( gfx_path_to(filename) )
        @progress_msg += "." ; early_progress
        
        @background_images[key] = @screen.create_texture_from(source_image)
        source_image.destroy
      }
    end

    ##
    # reads in the old sprites from the "undocumented" format I used.
    #
    def load_old_sprites
      sprite_images = []
      File.open( gfx_path_to('sprites.dat'), 'rb'){|file|
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
          sprite = SDL2::Surface.new(SPRITE_WIDTH,SPRITE_HEIGHT,@screen)

          sprite_data = file.read(1030)
          if sprite_data && sprite_data.size==1030 then
            x = 0
            y = 0
            sprite.lock
            # The first six bytes is garbage?
            sprite_data[6,1024].each_byte{|pixel|
              sprite.put_pixel(x,y,pixel)
              x += 1 # *self.scale_factor
              if x>31
                x = 0
                y += 1
              end              
            }
            # sprite.unlock
            # sprite.setColorKey( SDL2::SRCCOLORKEY || SDL2::RLEACCEL ,0)
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
        spritemap = SDL2::Surface.load( gfx_path_to('sprites.png') )
      rescue
        puts "FAILED: loading sprites!"
        return nil
      end

      spritemap_colkey = spritemap.pixel(0, 0)

      lines = ( spritemap.h + 15 ) / 32 

      (0...lines).each do|line| 
        @progress_msg += "." ; early_progress
        (0...10).each do|column|
          sprite = SDL2::Surface.new(SPRITE_WIDTH, SPRITE_HEIGHT, spritemap.bits_per_pixel)

          x =  column * 32
          y = line * 32
          w = h = 32

          if self.scale_factor == 1 then
            SDL2::Surface.blit(spritemap,SDL2::Rect[x,y,w,h], sprite, SDL2::Rect[0,0,w,h] )
          else
            linear_scale_image(spritemap,x,y, sprite, self.scale_factor )
          end

          sprite.color_key = spritemap_colkey

          sprite_texture = @screen.create_texture_from(sprite)

          sprite_images << sprite_texture # WAS: sprite.display_format
        end
      end

      @sprite_colorkey = spritemap_colkey

      puts "Sprites loaded: #{sprite_images.size}." if DEBUG

      spritemap.destroy

      sprite_images
    end



    ##
    # save sprites out to bitmap
    #
    def save_old_sprites( filename = "tmpgfx" )

      height = ( (@sprite_images.size / 10) + 1 ) * 32

      # spritemap = SDL2::Surface.new( SDL2::SRCCOLORKEY, @xsize, height, @screen )
      # spritemap.set_palette( SDL2::LOGPAL, @sprite_palette, 0 )

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
      text = sprintf "%9d", score   # fails on EeePC
      rect = SCORE_RECTANGLE
      screen_fill_rect(*rect) 
      write_text( text, rect[0]+2*self.scale_factor, rect[1]-2*self.scale_factor ) 
    end


    ##
    # Show a single line message centered in the 
    # maze view area.
    #
    def show_message( text, flip = true )
      rect = MAZE_VIEW_RECTANGLE
      screen_fill_rect(*rect)

      tw, th = @font32.size_text( text )

      x = rect[0] 
      y = rect[1]
      w = rect[2] 
      h = rect[3] 
      
      write_smooth_text(text, 
                 x + (w-tw)/2,
                 y + (h-th)/2, 
                 @font32 ) 
      self.flip if flip
    end

    ##
    # Show a multi-line message centered in the
    # maze view area.
    #
    def show_long_message( text, flip = true, fullscreen = false )
      rect = ( fullscreen ? FULLSCREEN : MAZE_VIEW_RECTANGLE)[0..3]
      screen_fill_rect( *rect )

      gth = 0
      lines = text.split("\n").collect do |line| 
        tw, th = @font32.size_text( line ) 
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

      self.flip if flip
    end

    
    ##
    # assumes life and mana are in range (0..100)
    #
    def update_life_and_mana( life, mana )
      rect = LIFE_MANA_RECTANGLE
      screen_fill_rect(*rect) 
      screen_fill_rect(rect[0], rect[1], 
                       rect[2]*life/100, rect[3]/2, 
                       COL_RED)  if life.between?(0,100)
      screen_fill_rect(rect[0], rect[1]+rect[3]/2, 
                       rect[2]*mana/100, rect[3]/2,
                       COL_BLUE) if mana.between?(0,100)      
    end

    def update_inventory( inventory )
      rect = INVENTORY_RECTANGLE
      screen_fill_rect(*rect) 
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
      screen_fill_rect( *rect1 )
      put_sprite( primary, *rect1[0,2]) 
      screen_fill_rect( *rect2 )
      put_sprite( secondary, *rect2[0,2]) 
    end

    def update_player( player_sprite )
      put_sprite(player_sprite, *PLAYER_SPRITE_POSITION )
    end



    ####################################
    # Experimental view updating trying 
    # to refactor and separate view logic
    # from the GameLoop as much as possible.
    ####################################

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
        '', # Failed for RubySDL2.0.1 and Ruby1.9.1-p1
        'Esc / Q :- Quit playing',
        'F9 / R :- Restart level',
        # '[F4]: Load game    [F5]: Save game',
        # '[S]: Sound on/off',
        'PgUp / PgDn :- Tune Volume',
        'Plus / Minus :- Tune Speed (on keypad)',
      ]
      
      y_offset = 0
      font = @font24
      lines.each{|line|
        write_smooth_text( line, 5, y_offset, font ) if line.size.nonzero? # Failed for RubySDL2.0.1 and Ruby1.9.1-p1 on empty string.
        y_offset+= font.height * 3 / 4 
      }
      
      flip
    end


    ####################################
    #
    def draw_map( player, line_by_line = false )
      map = player.location.map

      rect = MAZE_VIEW_RECTANGLE
      screen_fill_rect(*rect)

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
            screen_fill_rect(rect[0] + ax*map_block_size,
                              draw_y,
                              map_block_size,
                              map_block_size,
                              col)
          end   

        end

        # The center.
        screen_draw_rect(rect[0] + map_width/2  * map_block_size,
                          rect[1] + map_height/2 * map_block_size,
                          map_block_size,
                          map_block_size,
                          COL_WHITE)

      end

    end



    ##
    # Helper for doing gradual buildup of image.
    # Draws the same thing twice, once for immediate viewing,
    # and on the offscreen buffer for next round.
    #
    def draw_immediately_twice
      yield
      self.flip
      yield
    end


    ##
    # Prepare a large sprite containing the scrolltext
    #
    def prepare_scrolltext( text )
      font = @font32
      textsize = font.size_text( text )

      @scrolltext_surf = font.render_blended( text, [0xFF, 0xFF, 0xFF])
      @scrolltext = @screen.create_texture_from(@scrolltext_surf)
      @scrolltext_index = - @xsize
    end


    ##
    # Update the scrolltext area at the bottom of the screen.
    #
    def update_scrolltext
      w = @xsize
      h = 40 * self.scale_factor
      
      screen_fill_rect( 0, 200 * self.scale_factor, w, h, 0 )

      @screen.copy(@scrolltext,
        SDL2::Rect[@scrolltext_index, 0, w, h],
        SDL2::Rect[0, 200 * self.scale_factor, w, h])

      @scrolltext_index += 1 * self.scale_factor

      if @scrolltext_index > @scrolltext.w + @xsize
        @scrolltext_index = - @xsize
      end

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
        tw, th = font.size_text( text )
        max_width = [max_width,tw+16*self.scale_factor].max
        total_height += th + 4*self.scale_factor
      end
      @menu_width = max_width
      @menu_chosen_item = chosen || @menu_items.first
      
      # Truncate if the items can fit on screen.
      scr_height = 200 * self.scale_factor
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
      topx = 160 * self.scale_factor - @menu_width  / (2)
      topy = 120 * self.scale_factor - @menu_height / (2)

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

      screen_fill_rect( topx, topy, @menu_width,@menu_height, COL_BLACK )
      screen_draw_rect( topx, topy, @menu_width,@menu_height, COL_GRAY )
      y_offset = topy
      font = @font32
      curr_menu_items.each do |text|
        tw, _ = font.size_text( text )
        color_intensity = 127
        if text == @menu_chosen_item then
          rect = [ 
            topx + 4*self.scale_factor, 
            y_offset + 4*self.scale_factor,
            @menu_width - 8*self.scale_factor, 
            font.height - 4*self.scale_factor,
            COL_WHITE
          ]
          screen_draw_rect( *rect )
          color_intensity = 255
        end
        write_smooth_text(text, 
                          topx + (@menu_width-tw)/2, 
                          y_offset + 2*self.scale_factor, 
                          font, *[color_intensity]*3 )
        y_offset+= font.height + 4*self.scale_factor
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

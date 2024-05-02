module MagicMaze

  class GosuGame < MagicMaze::Game

    attr_reader :current_input

    def initialize(*args)
      super(*args)

      @title_input = Input::Control.new( self, :titlescreen )

      @current_input = @title_input
    end

    def update
      # print "."
    end

    def draw
      put_titlescreen
      # if menu...
    end

    def loop
      load_checkpoints

      puts "Starting loop..."
      @graphics.start_loop(self)
      puts "Started loop...."

      @graphics.fade_out
      save_checkpoints
      puts "Exiting..."
      destroy
    end

    def button_down(id)
      puts "button down #{id}"
      @current_input.check_key_press(id)
    end

    def exit_game
      @graphics.destroy
    end

    def open_game_menu
      # TODO: Actually show a menu here...
      select_game_checkpoint
    end

    def start_game( level = nil, player_status = nil )
      super(level, player_status)
      @current_input = Input::Control.new( @current_game, :in_game )
      @graphics.set_loop(@current_game, nil, self, nil )
    end


  end

 end

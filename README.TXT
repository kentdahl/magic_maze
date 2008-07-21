                    ---+*+---
           -----------++*++-----------
--------------------+++***+++----------------------
           M A G I C  -+*+-  M A Z E
--------------------+++***+++----------------------
           -----------++*++-----------
                    ---+*+---
 
 Copyright by Kent "MenThal" Dahl 
 
        (1995-1996) Version  1.2
	(1999)      Version  1.22
        (2004)      Version  1.4.1
        (2008)      Version  1.4.3

 This game is FREE as in both BEER and SPEECH.
      (Ruby and GPL dual-licenced.)

 E-mail me at:
   kentda<AT>pvv<DOT>org

___________________________________________________
*** Magic Maze and a Half ***

The 1.4.x (and subsequent 1.5.x) versions of 
Magic Maze is dubbed "Magic Maze and a Half", 
and is a port of MM to the language Ruby using SDL. 

It does not aim to introduce major new gameplay changes,
but some upgrades and improvements will rear their heads.

Hopefully there will be a playable version by the time
of the 10 year anniversary of the development start of
the original Turbo Pascal version, which began in
November 1994. 

___________________________________________________
*** Magic Maze: Two Tunnels ***

Please forgive the poor Lord of the Rings pun.
The 1.9.x and subsequent 2.x versions of Magic Maze is
dubbed "MM: Two Tunnels" and is a more long-term plan
to change gameplay more drastically. 

This is the experimental playground I'm setting up for
myself, and is less likely to show up this side of the
Apocolypse.


___________________________________________________
*** Controls ***

* Title screen *

Space / Return - start playing
Esc / Q        - quit game
F4             - load savegame

* In-game *       

Arrow keys - movement of the little blue wizard.
Ctrl       - cast missile spell (not implemented yet)
Space      - cast secondary spell (also "Alt" key)
Z and X    - leaf through missile spells in book
A and S    - leaf through secondary spells in book
Esc / Q    - exit game 
F1         - help
F9 / R     - restart level
F12	   - toggle fullscreen
PageUp/Dn  - tune volume
Plus/Minus - tune speed (on numeric keypad)


___________________________________________________
*** Command-line usage ***

Start Magic Maze by executing:

  ruby mm.rb

The following command-line options are available:

--nosound	Disables sound
--level [#]	Assign a start level (1-10)
--joystick [#]  Enable joystick support.
--help          Show command line options
--volume        Set volume (1-10)
--fullscreen    Start in fullscreen mode
--scale         Scale the graphics and resolution up (1-5)
--savedir       Directory to put savegame.
--loadgame      Automatically load the savegame.


___________________________________________________
*** Requirements ***

* Ruby 1.8 (or higher)
  - http://www.ruby-lang.org/

* SDL, SDL_image, SDL_mixer (version 1.2 or higher?)
  - http://www.libsdl.org/

* Ruby-SDL 0.9.x (or higher)
  - http://www.kmc.gr.jp/~ohai/rubysdl.en.html

___________________________________________________
*** Web-site ***

Magic Maze 1.4.x:
- http://magicmaze.rubyforge.org/

Magic Maze 1.2x:
- http://www.bigfoot.com/~MenThal/coding/mmaze/mmaze.html




___________________________________________________
*** Credits ***

Idea, design & coding:  MenThal (Kent Dahl)

Graphics:               MenThal

Level design:           Daniel Dahl
                        MenThal

Game testing:           Per Ejnar Thomsen   (original)
                        Daniel Dahl         (original and Ruby port)
			Randi Roervik	    (Ruby port)

Other:
- Free font found at: http://www.squaregear.net/fonts/ 


___________________________________________________
___________________________________________________

stds.serialism = {
   globals = {
      -- Debug tools
      "DEBUG",
      "log",

      -- Core functions
      "draw_serie",
      "init_params",
      "play_note",
      "tick",
      "invert_sequins",
      "reverse_sequins",
      "shuffle_sequins",

      -- Utility function
      "invert",
      "reverse",
      "shuffle",

      -- Global variables
      "HEIGHT",
      "WIDTH",
      "amp_serie",
      "cur_amp",
      "cur_div",
      "cur_note",
      "div_serie",
      "lat",
      "midi_dev",
      "note_serie",
      "sprocket",
      -- Clocks and metros
   }
}

stds.norns = {
   globals = {
      "init",
      "enc",
      "key",
      "redraw"
   },
   read_globals = {
      _menu = {
         fields = {
            "rebuild_params"
         }
      },
      clock = {
         fields = {
            "cancel",
            "run",
            "sleep",
            "sync",
            transport = {
               fields = {
                  "start",
                  "stop",
               }
            }
         }
      },
      controlspec = {
         fields = {
            "new",
            "MIDI",
            "MIDINOTE"
         }
      },
      metro = {
         fields = {
            "init"
         }
      },
      midi = {
         fields = {
            "cc",
            "connect",
            "note_on",
            "note_off"
         }
      },
      norns = {
         fields = {
            "is_shield"
         }
      },
      params = {
         fields = {
            "add_number",
            "add_control",
            "add_option",
            "add_separator",
	    "add_trigger",
            "bang",
            "delta",
            "hide",
            "get",
            "set",
            "set_action",
            "show",
         }
      },
      screen = {
         fields = {
            "circle",
            "clear",
            "fill",
            "font_face",
            "level",
            "line",
	    "line_rel",
            "move",
	    "move_rel",
            "stroke",
            "text",
            "update",
         }
      },
      ui = {
         Dial = {
            fields = {
               "new"
            }
         }
      }
   }
}

std = "lua51+norns+serialism"

-- Local Variables:
-- mode: lua
-- End:

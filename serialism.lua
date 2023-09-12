-- Reading Stockhausen's How Time Passes By (1957)
-- thinking about serialism.
-- Also https://www.youtube.com/watch?v=8sm3o-2cfIQ
--
-- Needs an edit mode, for now rando+operations.
--
-- by xmacex for norns a rainy Tuesday

DEBUG = true

local WIDTH = 128
local HEIGHT = 64

local sequins = require 'sequins'
local lattice = require 'lattice'

midi_dev = nil

note_serie = nil
local cur_note = nil
div_serie = nil
cur_div = nil
amp_serie = nil
cur_amp = nil
lat = nil
sprocket = nil

function init()
   init_params()
   midi_dev = midi.connect(params:get('midi_dev'), 1)

   note_serie    = sequins{1,2,3,4,5,6,7,8,9,10,11,12}
   -- note_serie = sequins{9,0,9,11} -- acab
   cur_note      = note_serie()
   -- div_serie     = sequins{1/1,1/2,1/3,1/4,1/5,1/6,1/7,1/8,1/9,1/10,1/11,1/12}
   div_serie     = sequins{1,2,3,4,5,6,7,8,9,10,11,12}
   cur_div       = 1 / div_serie()
   amp_serie     = sequins{1,2,3,4,5,6,7,8,9,10,11,12}
   cur_amp       = amp_serie()

   lat           = lattice:new{}
   lat:start()

   sprocket      = lat:new_sprocket{
      action = tick
   }
   sprocket:start()

   -- I still don't know what is the norns redraw pattern...
   clock.run(
      function()
         while true do
            clock.sleep(1/12)
            redraw()
         end
   end)
end

function init_params()
   params:add_number('midi_dev', "MIDI device", 1, 4, 1)
   params:set_action('midi_dev', function(d) midi_dev = midi.connect(d) log("MIDI dev now "..midi_dev.name) end)
   params:add_number('midi_ch', "MIDI channel", 1, 16, 1)
   params:add_number('root', "root note", 0, 127, 60)
   params:add_control('note_len', "note_len", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
   params:add_number('speedup', "speedup", 1, 8, 1)

   params:add_separator("what_to_do", "serializations")
   params:add_option('do_notes', "serialize notes", {"on", "off"}, 1)
   params:set('do_notes', 1)    -- binary or default value above isn't working
   params:add_option('do_amps',  "serialize amps", {"on", "off"}, 2)
   params:set('do_amps', 2)     -- binary or default value above isn't working.
   params:add_option('do_divs',  "serialize divisions", {"on", "off"}, 1)
   params:set('do_divs', 1)     -- binary or default value above isn't working.

   params:add_separator("randozone", "randozone")
   params:add_trigger('shuffle_notes', "shuffle notes")
   params:set_action('shuffle_notes', function() shuffle_sequins(note_serie) end)
   params:add_trigger('shuffle_amps', "shuffle amps")
   params:set_action('shuffle_amps', function() shuffle_sequins(amp_serie) end)
   params:add_trigger('shuffle_divs', "shuffle divs")
   params:set_action('shuffle_divs', function() shuffle_sequins(div_serie) end)

   params:add_separator("R", "reversezone")
   params:add_trigger('reverse_notes', "reverse notes")
   params:set_action('reverse_notes', function() reverse_sequins(note_serie) end)
   params:add_trigger('reverse_amps', "reverse amps")
   params:set_action('reverse_amps', function() reverse_sequins(amp_serie) end)
   params:add_trigger('reverse_divs', "reverse divs")
   params:set_action('reverse_divs', function() reverse_sequins(div_serie) end)

   params:add_separator("I", "flipzone")
   params:add_trigger('invert_notes', "invert notes")
   params:set_action('invert_notes', function() invert_sequins(note_serie) end)
   params:add_trigger('invert_amps', "invert amps")
   params:set_action('invert_amps', function() invert_sequins(amp_serie) end)
   params:add_trigger('invert_divs', "invert divs")
   params:set_action('invert_divs', function() invert_sequins(div_serie) end)
end

function redraw()
   screen.clear()
   draw_serie()
   screen.update()
end

function draw_serie()
   local x_scale = WIDTH/#note_serie -- 78 is a number too
   local y_scale = #note_serie/HEIGHT*2
   screen.level(3)
   screen.move(0, HEIGHT-params:get('root')*y_scale*2)
   for i,v in ipairs(note_serie) do
      -- screen.move_rel(-1+div_serie[i], -v)
      -- local x=(i-1)*x_scale
      local x=i*x_scale
      local y=HEIGHT-(params:get('root')+v)*y_scale
      local l=#div_serie-div_serie[i]+1
      screen.move(x, y)
      if v == cur_note then
	 screen.level(10)
      else
	 screen.level(2)
      end
      screen.line(x-l, y)
      screen.stroke()
      if DEBUG then screen.font_face(#note_serie) screen.text(v) end
      -- screen.line_rel(-(1/div_serie[i])*x_scale, y_scale)
      -- screen.move_rel(0, v)
   end
end

function tick()
   if params:get('do_notes') == 1  then
      cur_note = note_serie()
   end
   if params:get('do_amps') == 1 then
      cur_amp = amp_serie()
   end
   if params:get('do_divs') == 1 then
      sprocket:set_division(1/div_serie() / params:get('speedup'))
   else
      sprocket:set_division(1/params:get('speedup'))
   end
   play_note()
end

function play_note()
   local abs_note = params:get('root')+cur_note
   local abs_amp  = math.floor(cur_amp * 127 / #amp_serie)
   if midi_dev then
      midi_dev:note_on(abs_note, abs_amp, params:get('midi_ch'))
      -- note management routine from @dan_derks at
      -- https://llllllll.co/t/norns-midi-note-on-note-off-management/35905/5?u=xmacex
      clock.run(
         function()
            clock.sleep(params:get('note_len'))
            midi_dev:note_off(abs_note, 0, params:get('midi_ch'))
         end
      )
   end
end

function enc(n, d)
   if n==2 then
      params:delta('root', d)
   end
end

function key(k, z)
   if k==2 and z==1 then
      shuffle_sequins(note_serie)
   elseif k==3 and z==1 then
      shuffle_sequins(div_serie)
   end
end

-- Fisher Yates shuffle by Sneitnick
-- https://gist.github.com/Uradamus/10323382?permalink_comment_id=2754684#gistcomment-2754684
function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function shuffle_sequins(seq)
   shuffle(seq.data)
end

function reverse(tbl)
   for i = 1, #tbl//2, 1 do
      tbl[i], tbl[#tbl-i+1] = tbl[#tbl-i+1], tbl[i]
   end
end

function reverse_sequins(seq)
   reverse(seq.data)
end

function invert(tbl)
   for i = 1, #tbl, 1 do
      tbl[i] = #tbl - tbl[i]
   end
end

function invert_sequins(seq)
   invert(seq.data)
end

function log(message)
   if DEBUG then print(message) end
end

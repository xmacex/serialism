-- I was reading Stockhausen's
--   How Time Passes (1957)
-- thinking about serialism.
-- Also youtu.be/8sm3o-2cfIQ
--
-- K2 shuffle notes
-- K3 shuffle divisions
-- E2 transpose ↑/↓
-- Shuffing, reversing, inverting
--   in the menus.
--
-- by xmacex
--  on a rainy day

DEBUG = false

local WIDTH = 128
local HEIGHT = 64

sequins = require 'sequins'
lattice = require 'lattice'
TWELVE = {1,2,3,4,5,6,7,8,9,10,11,12}

midi_dev = nil

lat      = nil
sprocket = nil

note_serie = nil
cur_note   = nil
div_serie   = nil
cur_div     = nil
amp_serie    = nil
cur_amp      = nil

-- Initialization.
function init()
   init_params()
   midi_dev = midi.connect(params:get('midi_dev'), 1)

   note_serie = sequins(TWELVE)
   cur_note   = note_serie()
   div_serie  = sequins(TWELVE)
   cur_div    = 1 / div_serie()
   amp_serie  = sequins(TWELVE)
   cur_amp    = amp_serie()

   lat        = lattice:new{}
   lat:start()

   sprocket   = lat:new_sprocket{action = tick}
   sprocket:start()

   -- Let's do this kind of redraw pattern this time :)
   clock.run(
      function()
         while true do
            clock.sleep(1/#TWELVE)
            redraw()
         end
   end)
end

function init_params()
   -- playing stuff
   params:add_number('midi_dev', "MIDI device", 1, 4, 1, function(p) local midi_dev = midi.connect(p.value) return p.value..": "..midi_dev.name end)
   params:set_action('midi_dev', function(d) midi_dev = midi.connect(d) log("MIDI dev now "..midi_dev.name) end)
   params:add_number('midi_ch', "MIDI channel", 1, 16, 1)
   params:add_number('root', "root note", 0, 127-#TWELVE, 60)
   params:add_control('note_len', "note length", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
   params:add_number('speedup', "faster faster", 1, #TWELVE, 1)

   -- serializations
   params:add_separator('serializations', "serializations")
   params:add_binary('do_notes', "serialize notes", 'toggle', 1)
   params:add_binary('do_amps', "serialize amps", 'toggle', 1)
   params:add_binary('do_divs', "serialize divs", 'toggle', 1)

   -- randozone
   params:add_separator("randozone", "randozone")
   params:add_trigger('shuffle_notes', "shuffle notes")
   params:set_action('shuffle_notes', function() shuffle_sequins(note_serie) end)
   params:add_trigger('shuffle_amps', "shuffle amps")
   params:set_action('shuffle_amps', function() shuffle_sequins(amp_serie) end)
   params:add_trigger('shuffle_divs', "shuffle divs")
   params:set_action('shuffle_divs', function() shuffle_sequins(div_serie) end)

   -- reversezone
   params:add_separator("reversezone", "reversezone")
   params:add_trigger('reverse_notes', "reverse notes")
   params:set_action('reverse_notes', function() reverse_sequins(note_serie) end)
   params:add_trigger('reverse_amps', "reverse amps")
   params:set_action('reverse_amps', function() reverse_sequins(amp_serie) end)
   params:add_trigger('reverse_divs', "reverse divs")
   params:set_action('reverse_divs', function() reverse_sequins(div_serie) end)

   -- invertzone
   params:add_separator("invertzone", "invertzone")
   params:add_trigger('invert_notes', "invert notes")
   params:set_action('invert_notes', function() invert_sequins(note_serie) end)
   params:add_trigger('invert_amps', "invert amps")
   params:set_action('invert_amps', function() invert_sequins(amp_serie) end)
   params:add_trigger('invert_divs', "invert divs")
   params:set_action('invert_divs', function() invert_sequins(div_serie) end)
end

-- Time handling
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

-- User interface.
--- User input
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

--- Screen
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

-- Sequins management and utilities.
--- Fisher Yates shuffle by Sneitnick
--- https://gist.github.com/Uradamus/10323382?permalink_comment_id=2754684#gistcomment-2754684
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
      tbl[i] = #tbl - tbl[i] + 1
   end
end

function invert_sequins(seq)
   invert(seq.data)
end

-- Other utilities.
function log(message)
   if DEBUG then print(message) end
end

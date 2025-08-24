-- I was reading Stockhausen's
--  How Time Passes (1957)
--   thinking about serialism.
--    Also youtu.be/8sm3o-2cfIQ
--     E1 select a serie
--      E2 select one item
--       E3 and the other one
--        K2 then swap them
--         K3 and shuffle serie
--          K1+K2 and reverse it
--           K1+K3 and invert it
--            by xmacex

sequins = require 'sequins'
 lattice = require 'lattice'
  TWELVE = {1,2,3,4,5,6,7,8,9,10,11,12}
   WIDTH = 128
    HEIGHT = 64
     X_SCALE = 0
      Y_SCALE = 0
       midi_dev = nil
        sel_serie = 1
         sel_first = 1
          sel_second = #TWELVE
           shift = 0
 
lat = nil
 sprocket = nil
  note_serie= {}
   cur_note = nil
    div_serie = {}
     cur_div = nil
      amp_serie = {}
       cur_amp = nil
        series = {}
         SERIE_NAMES = {"note",
          "div",
           "amp"}


function init()
--- Params
---- playing stuff
params:add_number('midi_dev', "MIDI device", 1, 4, 1, function(p) local midi_dev = midi.connect(p.value) return p.value..": "..midi_dev.name end)
params:set_action('midi_dev', function(d) midi_dev = midi.connect(d) log("MIDI dev now "..midi_dev.name) end)
params:add_number('midi_ch', "MIDI channel", 1, 16, 1)
params:add_number('root', "root note", 0, 127-#TWELVE, #TWELVE*5)
params:add_control('note_len', "note length", controlspec.new(0.05, 1, 'lin', 0.01, 0.1, "sec"))
params:add_number('speedup', "faster faster", 1, #TWELVE, 1)

---- serializations
params:add_separator('serializations', "serializations")
params:add_binary('do_notes', "serialize notes", 'toggle', 1)
params:add_binary('do_amps', "serialize amps", 'toggle', 1)
params:add_binary('do_divs', "serialize divs", 'toggle', 1)

---- randozone
params:add_separator("randozone", "randozone")
params:add_trigger('shuffle_notes', "shuffle notes")
params:set_action('shuffle_notes', function() shuffle_sequins(note_serie) end)
params:add_trigger('shuffle_amps', "shuffle amps")
params:set_action('shuffle_amps', function() shuffle_sequins(amp_serie) end)
params:add_trigger('shuffle_divs', "shuffle divs")
params:set_action('shuffle_divs', function() shuffle_sequins(div_serie) end)

---- reversezone
params:add_separator("reversezone", "reversezone")
params:add_trigger('reverse_notes', "reverse notes")
params:set_action('reverse_notes', function() reverse_sequins(note_serie) end)
params:add_trigger('reverse_amps', "reverse amps")
params:set_action('reverse_amps', function() reverse_sequins(amp_serie) end)
params:add_trigger('reverse_divs', "reverse divs")
params:set_action('reverse_divs', function() reverse_sequins(div_serie) end)

---- invertzone
params:add_separator("invertzone", "invertzone")
params:add_trigger('invert_notes', "invert notes")
params:set_action('invert_notes', function() invert_sequins(note_serie) end)
params:add_trigger('invert_amps', "invert amps")
params:set_action('invert_amps', function() invert_sequins(amp_serie) end)
params:add_trigger('invert_divs', "invert divs")
params:set_action('invert_divs', function() invert_sequins(div_serie) end)

--- Other initialization
midi_dev = midi.connect(params:get('midi_dev'), 1)

note_serie = sequins(tab.gather(TWELVE, {}))
cur_note   = note_serie()
div_serie  = sequins(tab.gather(TWELVE, {}))
cur_div    = 1 / div_serie()
amp_serie  = sequins(tab.gather(TWELVE, {}))
cur_amp    = amp_serie()

series     = {note_serie, div_serie, amp_serie}

lat        = lattice:new{}
lat:start()

sprocket   = lat:new_sprocket{action = tick}
sprocket:start()

X_SCALE = WIDTH/#note_serie -- 78 is a number too
Y_SCALE = #note_serie/HEIGHT*2

-- Let's do this kind of redraw pattern this time :)
clock.run(
function()
while true do
clock.sleep(1/#TWELVE)
redraw()
end
end)
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
    if n==1 then
        sel_serie = util.wrap(sel_serie+d, 1, #series)
    elseif n==2 then
        sel_first=util.wrap(sel_first+d, 1, #TWELVE)
        if sel_first == sel_second then sel_first=sel_first+d end
    elseif n==3 then
        sel_second=util.wrap(sel_second+d, 1, #TWELVE)
        if sel_second == sel_first then sel_second=sel_second+d end
    end
end

function key(k, z)
    if k==1 then
        shift=z
    end
    if k==2 and z==1 then
        if shift==1 then
            reverse_sequins(series[sel_serie])
        else
            swap(series[sel_serie], sel_first, sel_second)
        end
    elseif k==3 and z==1 then
        if shift==1 then
            invert_sequins(series[sel_serie])
        else
            shuffle_sequins(series[sel_serie])
        end
    end
    end

function gamepad.dpad(axis, sign)
    if axis=='X' then
        enc(2, sign)
    elseif axis=='Y' then
        enc(3, sign)
    end
end

function gamepad.button(button_name, state)
    if button_name=='SELECT' and state==1 then
        enc(1, 1)
    elseif button_name=='A' then
        key(2, state)
    elseif button_name=='B' then
        key(3, state)
    elseif button_name=='START' then
        key(1, state)
    end
end

     --- Screen
     function redraw()
         screen.clear()

         redraw_selectors(sel_first, sel_second)
         redraw_serie_name(SERIE_NAMES[sel_serie])
         redraw_serialism()
     screen.update()
     end

function redraw_selectors(i1, i2)
    local x1 = i1*X_SCALE
    local y1 = HEIGHT-(params:get('root')+note_serie.data[i1])*Y_SCALE
    local l1 = #div_serie-div_serie[i1]

    screen.level(1)

    screen.move(0, 1)
    screen.line(x1-l1, y1)
    screen.line(x1, y1)
    screen.line(WIDTH, 1)
    screen.fill()

    local x2 = i2*X_SCALE
    local y2 = HEIGHT-(params:get('root')+note_serie.data[i2])*Y_SCALE
    local l2 = #div_serie-div_serie[i2]
    screen.move(1, HEIGHT)
    screen.line(x2-l2, y2)
    screen.line(x2, y2)
    screen.line(WIDTH, HEIGHT)
    screen.fill()
end

function redraw_serie_name(name)
    screen.font_face(#TWELVE)
    screen.font_size(#TWELVE)
    screen.level(#TWELVE)

    screen.move(#TWELVE+shift, #TWELVE)
    screen.text_center(name)

    screen.move(WIDTH-#TWELVE-shift, HEIGHT-#TWELVE)
    screen.text_center(name)
end

function redraw_serialism()
    screen.level(3)
    screen.move(0, HEIGHT-params:get('root')*Y_SCALE*2)
    for i,v in ipairs(note_serie) do
        local x=i*X_SCALE
        local y=HEIGHT-(params:get('root')+v)*Y_SCALE
        local l=#div_serie-div_serie[i]+1
        screen.move(x, y)
        if v == cur_note then
            screen.level(16)
        else
            screen.level(amp_serie.data[v])
        end
        screen.line(x-l, y)
        screen.stroke()
    end
end

      -- Sequins management and utilities.
function swap(serie, i1, i2)
    local t1 = serie.data[i1]
    serie.data[i1] = serie.data[i2]
    serie.data[i2] = t1
end
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

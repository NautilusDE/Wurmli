' Pal246Lib - a small palette effects library for the CMM2 (8bit mode)
' --------------------------------------------------------------------
' 2021 by nautilus
'
' version: 0.1: tested on firmware 5.06
'          0.2: found a bug in the fading subs
'          0.3: global variable FadingStep%, to change the speed of fading effects
'
' in main program you have to set
' option base 0


dim myCLUT%(256)    'colour lookup table
dim FadingStep% = 4 'change the speed of fading effects, usable values are 1 .. 6, default is 2

'recreate the CMM2 8bit sytem palette into myCLUT% (FM 5.06)
sub LoadSystemPalette
  local r%(7) = (&h000000, &h200000, &h480000, &h680000, &h900000, &hB00000, &hD00000, &hE00000)
  local g%(7) = (&h000000, &h002400, &h004800, &h006800, &h009000, &h00B000, &h00D000, &h00E000)
  local b%(3) = (&h000000, &h000050, &h0000A8, &h0000E0)
  local i%,map_r%, map_g%, map_b%
  for i% = 0 to 255
    map_r% = i% \ 32
    map_g% = (i% mod 32) \ 4
    map_b% = i% mod 4
    myCLUT%(i%) = r%(map_r%) + g%(map_g%) + b%(map_b%)
  next i%
  myCLUT%(4) = &h000100   'special NOTBLACK colour since FM 5.06
end sub

'set myCLUT%() as the active palette
sub SetPalette
  local i%
  for i% = 0 to 255
      map(i%) = myCLUT%(i%)
  next i%
  map set
end sub

'set all colours to black
sub SetPaletteToBlack
  local i%
  for i% = 0 to 255
    map(i%) = 0
  next i%
  map set
end sub

sub FadeInPalette
  local r%, g%, b%, i%, j%
  for j%= 255 to 0 step (-1 * FadingStep%)
    for i% = 0 to 255
      r% = (myCLUT%(i%) and &Hff0000) \ 65536 - j%
      if r% < 0 then r% = 0
      g% = (myCLUT%(i%) and &H00ff00) \ 256 - j%
      if g% < 0 then g% = 0
      b% = (myCLUT%(i%) and &HFF) - j%
      if b% < 0 then b% = 0
      map(i%) = rgb(r%, g%, b%)
    next i%
    map set
  next j%
  SetPalette
end sub

sub FadeOutPalette
  local r%, g%, b%, i%, j%
  for j%= 0 to 255 step FadingStep%
    for i% = 0 to 255
      r% = (myCLUT%(i%) and &Hff0000) \ 65536 - j%
      if r% < 0 then r% = 0
      g% = (myCLUT%(i%) and &H00ff00) \ 256 - j%
      if g% < 0 then g% = 0
      b% = (myCLUT%(i%) and &HFF) - j% 
      if b% < 0 then b% = 0
      map(i%) = rgb(r%, g%, b%)
    next i%
    map set
  next j%
  SetPaletteToBlack
end sub

sub Grayscale
  local r%, g%, b%, brightness%, i%
  for i% = 0 to 255
    r% = (map(i%) and &Hff0000) \ 65536
    g% = (map(i%) and &H00ff00) \ 256
    b% = map(i%) and &HFF
    brightness% = (r% * 299 + g% * 587 + b% * 114) \ 1000
    map(i%) = rgb(brightness%, brightness%, brightness%)
  next i%
  map set
end sub
 

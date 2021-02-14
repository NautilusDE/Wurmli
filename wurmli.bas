option base 0
option explicit

' WURMLI - a snake game for the CMM2
' --------------------------------------------------------------------
' 2021 by nautilus
'
' version: 1.0: first release, tested on firmware 5.06 - have fun :)

#include "Pal256Lib.inc"

Const SNAKE_MAX_LENGTH = 36

Const PF_WIDTH = 49
Const PF_HEIGHT = 35

Const TILE_FREE = 0
Const TILE_BRICK = 1
Const TILE_DIAMOND = 2
Const TILE_SNAKE = 3

const KEY_ESC = 27
const KEY_SPACE = 32
const KEY_UP = 128
const KEY_LEFT = 130
const KEY_DOWN = 129
const KEY_RIGHT = 131
const KEY_ENTER = 10

const MODE_PLAY = 1
const MODE_EXIT = 2
const MODE_MENU = 3
const MODE_CREDITS = 4
const MODE_INSTRUCTIONS = 5
const MODE_HIGHSCORE = 6
const MODE_EXIT_PROGRAM = 7

const UP = 1
const LEFT = 2
const DOWN = 3
const RIGHT = 4

Dim Playfield%(PF_WIDTH,PF_HEIGHT)
Dim Snake_X%(SNAKE_MAX_LENGTH)
dim Snake_Y%(SNAKE_MAX_LENGTH)
dim Snake_Length%
dim Game_Mode% = MODE_CREDITS
dim Snake_Direction% = RIGHT
dim Snake_Colour% = 0
dim Game_Delay%
dim MenuItem% = 1
dim Life%, Score%
dim HighScore%(10) = (10000, 1000, 800, 600, 400, 200, 100, 50, 25, 10, 0)
dim HSName$(10)
HSName$(0) = "################"
HSName$(1) = "#....WURMLI....#"
HSName$(2) = "#..............#"
HSName$(3) = "#....*...ooo...#"
HSName$(4) = "#..........o...#"
HSName$(5) = "#..........o...#"
HSName$(6) = "#..ooooooooo...#"
HSName$(7) = "#..o...........#"
HSName$(8) = "#..............#"
HSName$(9) = "################"
HSName$(10) = "" 'hidden entry

dim i%

'Init Game
mode 1,8
cls
LoadSystemPalette
SetPalette
nautilus
'loading highscore
LoadHighscore
'loading the tileset in page 3
page write 3
cls
load bmp mm.info$(path) + "wurmli.bmp"
'load music and sound effects
play modfile mm.info$(path) + "musix-shine.mod"
play pause
play volume 50,50
'drawing the playfield in page 2
page write 2
cls
for i% = 0 to 49
  blit 560, 0, i%*16, 0, 16, 16, 3
  blit 560, 0, i%*16, 560, 16, 16, 3
next i%
for i% = 1 to 34
  blit 560, 0, 0, i%*16, 16, 16, 3
  blit 560, 0, 784, i%*16, 16, 16, 3
next i%
'blitting hearts
blit 688, 0, 736, 580, 16, 16, 3
blit 688, 0, 752, 580, 16, 16, 3
blit 688, 0, 768, 580, 16, 16, 3
'blitting score
blit 704, 0, 16, 580, 16, 16, 3
blit 256, 16, 48, 580, 16, 16, 3
pause 2000
' running the fancy game intro
page write 0
cls
PlayIntro
pause 500
RetroPrint ("Nautilus presents",272,16)
DrawCredits

play resume

'--------------
' main loop
'--------------
timer = 0
do
  if timer>7000 then
    timer = 0
    select case Game_Mode%
      case MODE_CREDITS
        Game_Mode% = MODE_INSTRUCTIONS
        DrawInstructions
      case MODE_INSTRUCTIONS
        Game_Mode% = MODE_HIGHSCORE
        DrawHighscore
      case MODE_HIGHSCORE
        Game_Mode% = MODE_CREDITS
        DrawCredits
      case MODE_MENU
        Game_Mode% = MODE_CREDITS
        DrawCredits
      case else
    end select
  end if
  i% = keydown(1)
  if i% <> 0 then 
    if Game_Mode% <> MODE_MENU then DrawMenu:DrawMenuItem(1)
    Game_Mode% = MODE_MENU
    timer = 0
  end if
  select case i%
    case KEY_DOWN
      DrawMenuItem(0)
      MenuItem% = MenuItem% + 1
      if MenuItem% > 4 then MenuItem% = 1
      DrawMenuItem(1)
      do: loop until keydown(1) = 0
      timer = 0
    case KEY_UP
      DrawMenuItem(0)
      MenuItem% = MenuItem% - 1
      if MenuItem% < 1 then MenuItem% = 4
      DrawMenuItem(1)
      do: loop until keydown(1) = 0
      timer = 0
    case KEY_ENTER
      if MenuItem% = 4 then
        Game_Mode% = MODE_EXIT_PROGRAM
      else 'start a new game
        page copy 0,1 'save the menu screen to page 1
        FadeOutPalette
        Game_Mode% = MODE_PLAY
        if MenuItem% = 1 then Game_Delay% = 180   'slow speed
        if MenuItem% = 2 then Game_Delay% = 120   'medium speed
        if MenuItem% = 3 then Game_Delay% = 80    'fast speed
        SetPlayfield
        SetSnake
        DrawPlayfield
        FadeInPalette
        SetDiamond
        GameLoop
        FadeOutPalette
        page copy 1,0 'restore menu screen
        FadeInPalette
        Game_Mode% = MODE_MENU
        timer = 0
      end if
    case else
  end select
loop until Game_Mode% = MODE_EXIT_PROGRAM
'--------------
' end main loop
'--------------
play stop
SaveHighscore
FadeOutPalette
cls
map reset
Print "Bye!"
end
'--------------
' end program
'--------------


sub GameLoop
  life% = 3
  score% = 0
  do while  Game_Mode% = MODE_PLAY
    timer = 0
    do
      CheckKeyInput
    loop until timer >= Game_Delay%
    MoveSnake
  loop
  CheckHighscore
end sub

sub CheckKeyInput
  select case keydown(1)
    case KEY_UP
      if Snake_Direction% <> DOWN then Snake_Direction% = UP
    case KEY_DOWN
      if Snake_Direction% <> UP then Snake_Direction% = DOWN
    case KEY_LEFT
      if Snake_Direction% <> RIGHT then Snake_Direction% = LEFT
    case KEY_RIGHT
      if Snake_Direction% <> LEFT then Snake_Direction% = RIGHT
    case KEY_SPACE
      Grayscale
      do:loop until keydown(1) = 0
      'paused the game
      do:loop until keydown(1) = KEY_SPACE
      do:loop until keydown(1) = 0
      SetPalette
    case KEY_ESC
      Game_Mode% = MODE_EXIT
    case else
  end select
end sub

sub MoveSnake
  local i%
  for i% = Snake_Length%-1 to 0 step -1
    Snake_X%(i%+1) = Snake_X%(i%)
    Snake_Y%(i%+1) = Snake_Y%(i%)
  next i%
  if Snake_Direction% = RIGHT then Snake_X%(0) = Snake_X%(1) + 1
  if Snake_Direction% = LEFT then Snake_X%(0) = Snake_X%(1) - 1
  if Snake_Direction% = UP then Snake_Y%(0) = Snake_Y%(1) - 1
  if Snake_Direction% = DOWN then Snake_Y%(0) = Snake_Y%(1) + 1

  select case Playfield%(Snake_X%(0),Snake_Y%(0)) 
    case TILE_BRICK, TILE_SNAKE
      blit 672, 0, (45+Life%)*16, 580, 16, 16, 3
      Life% = Life% - 1
      PlayBRRRB
      if Life% = 0 then
        Game_Mode% = MODE_EXIT
        exit sub
      else
        pause 1000
        SetPlayfield
        SetSnake
        'DrawPlayfield
        box 16, 16, 768, 544, , rgb(BLACK), rgb(BLACK)
        SetDiamond
      end if
    case TILE_DIAMOND
      Snake_Length% = Snake_Length% + 3
      score% = score% + 10 * MenuItem%
      SetDiamond
      PlayDrop
      if Snake_Length% >= SNAKE_MAX_LENGTH then
        PlayKuckuck
        Snake_Length% = 6
        score% = score% + 100 * MenuItem%
        for i% = Snake_Length%+1 to SNAKE_MAX_LENGTH
          Snake_X%(i%) = 0
          Snake_Y%(i%) = 0
        next i%
      end if
      RetroPrint(str$(score%), 48, 580)
    case else
  end select

  Snake_Colour% = Snake_Colour% + 1
  if Snake_Colour% > 34 then Snake_Colour% = 1
  blit Snake_Colour%*16,0, Snake_X%(0)*16, Snake_Y%(0)*16, 16, 16, 3
  Playfield%(Snake_X%(0),Snake_Y%(0)) = TILE_SNAKE
  if Snake_X%(Snake_Length%) > 0 then
    blit 0, 0, Snake_X%(Snake_Length%)*16, Snake_Y%(Snake_Length%)*16, 16, 16, 3
    Playfield%(Snake_X%(Snake_Length%), Snake_Y%(Snake_Length%)) = TILE_FREE
  end if  
end sub

sub SetPlayfield
  local x%, y%
  For y% = 1 to PF_HEIGHT-1
    For x% = 1 to PF_WIDTH-1
      Playfield%(x%, y%) = TILE_FREE
    next x%
  next y%
  For x% = 0 to PF_WIDTH
    Playfield%(x%,0) = TILE_BRICK
    Playfield%(x%,PF_HEIGHT) = TILE_BRICK
  next x%
  for y% = 0 to PF_HEIGHT
    playfield%(0,y%) = TILE_BRICK
    playfield%(PF_WIDTH,y%) = TILE_BRICK
  next y%
end sub

sub SetSnake
  local i%
  Snake_X%(0) = 24
  Snake_Y%(0) = 17
  Snake_Length% = 6
  Snake_Direction% = RIGHT  
  Playfield%(Snake_X%(0), Snake_Y%(0)) = TILE_SNAKE
  for i% = 1 to SNAKE_MAX_LENGTH
    Snake_X%(i%) = 0
    Snake_Y%(i%) = 0
  next i%

end sub

sub SetDiamond
  local x% = 0, y% = 0
  do
    x% = int (rnd * PF_WIDTH)
    y% = int (rnd * PF_HEIGHT)
  loop until Playfield%(x%,y%) = TILE_FREE
  Playfield%(x% , y%) = TILE_DIAMOND
  DrawDiamond(x%, y%)
end sub

sub DrawPlayfield
  page copy 2,0
end sub

sub DrawDiamond (x%, y%)
  blit (int(rnd*6)+36)*16, 0, x%*16, y%*16, 16, 16, 3 
end sub

sub RetroPrint (text$, x%, y%)
  local i%, char%
  local x2% = x%
  for i% = 1 to len(text$)
    char% = asc(mid$(text$, i%, 1))
    blit (char%-32) mod 50 * 16, (char%-32) \ 50  * 16+16, x2%, y%, 16, 16, 3
    x2% = x2% + 16
  next i%
end sub

sub DrawCredits
  box 0,256,799,344,,rgb(black), rgb(black)
  RetroPrint("a snake game for the CMM2", 208, 326)
  RetroPrint("code and graphics by Nautilus", 176, 374)
  RetroPrint("music by m0d", 304, 406)
  RetroPrint("press any key to continue", 208, 576)
end sub

sub DrawInstructions
  box 0,256,799,344,,rgb(black), rgb(black)
  RetroPrint("Use the arrow keys to move the snake.", 112, 326)
  Retroprint("Eat diamonds to grow.", 240, 358)
  RetroPrint("Stay on the board and don't crash into yourself.", 16, 390)
  RetroPrint("Press SPACE to pause and ESC to exit the game.", 32, 422)
  RetroPrint("press any key to continue", 208, 576)
end sub

sub DrawHighscore
  Local i%
  box 0,256,799,344,,rgb(black), rgb(black)
  RetroPrint("** HIGHSCORE **", 288, 326)
  for i% = 0 to 9
    Retroprint(HSName$(i%), 144, 358+i%*16)
    Retroprint(Str$(HighScore%(i%),16), 400, 358+i%*16)
  next i%
  RetroPrint("press any key to continue", 208, 576)
end sub

sub DrawMenu
  box 0,256,799,344,,rgb(black), rgb(black)
  RetroPrint("***  GAME  MENU  ***",240,326)
  Retroprint("  Slow  ",336,358)
  Retroprint(" Medium ",336,390)
  Retroprint("  Fast  ",336,422)
  Retroprint("  Exit  ",336,454)
  RetroPrint("choose a menu item",256,576)
end sub

sub DrawMenuItem(type%)
' type% = 0 or 1; 0 type space; 1 type >  <
  if type% = 0 then
    RetroPrint(" ", 304, MenuItem% * 32 + 326)
    RetroPrint(" ", 480, MenuItem% * 32 + 326)
  else
    RetroPrint(">", 304, MenuItem% * 32 + 326)
    RetroPrint("<", 480, MenuItem% * 32 + 326)
  end if
end sub

sub CheckHighscore
  local i%
  local a$
  if Score% > Highscore%(9) then a$ = GetPlayerName$()
  for i% = 9 to 0 step -1
    if Score% > HighScore%(i%) then
      HighScore%(i%+1) = HighScore%(i%)
      HSName$(i%+1) = HSName$(i%)
      HighScore%(i%) = Score%
      HSName$(i%) = a$
    end if
  next i%
end sub

function GetPlayerName$()
  local i%, k%
  local a$ = ""
  for i% = 0 to 20
    blit 560, 0, 240 + i% * 16, 240, 16, 16, 3
    blit 560, 0, 240 + i% * 16, 336, 16, 16, 3
  next i%
  for i% = 0 to 4
    blit 560, 0, 240, 256 + i% * 16, 16, 16, 3
    blit 560, 0, 560, 256 + i% * 16, 16, 16, 3
  next i%
  box 256, 256, 304, 80, 1, rgb(black), rgb(black)
  Retroprint("enter your name", 288, 272)
  Retroprint(a$+"_", 288, 304)
  do 
    k% = keydown(1)
    select case k%
      case 32 to 122
        if len(a$) < 16 then
          a$ = a$ + CHR$(k%)
          Retroprint(a$+"_", 288, 304)
          pause 100
        end if
      case 8
        if len(a$) > 0 then
          a$ = left$(a$,(len(a$)-1))
          Retroprint(a$+"_ ", 288, 304)
          pause 100
        end if
      case else
    end select 
  loop until k% = 10
  GetPlayerName$ = a$
end function

sub SaveHighscore
  local i%
  on error skip
  open mm.info$(path) + "wurmli.dat" for output as #1
  if mm.errno = 0 then
    for i% = 0 to 9
      print #1, HSName$(i%)
      print #1, Highscore%(i%)
    next i%
    close #1
  end if
end sub

sub LoadHighscore
  local i%
  on error skip
  open mm.info$(path) + "wurmli.dat" for input as #1
  if mm.errno = 0 then
    for i% = 0 to 9
      input #1, HSName$(i%)
      input #1, Highscore%(i%)
    next i%
    close #1
  end if
end sub

sub PlayDrop
  play modsample 30, 1, 64, 8272
end sub

sub PlayKuckuck
  play modsample 31, 1, 64, 8272
  pause 700
end sub

sub PlayBRRRB
  play modsample 29, 1, 64, 8272
  pause 2000
end sub

sub nautilus
  local s = 70
  local i%
  turtle reset
  turtle pen up
  turtle move 350,300
  turtle heading 90
  turtle pen down
  for i% = 1 to 50
    turtle forward s
    turtle turn left 90
    turtle forward s
    turtle turn left 90
    turtle forward s
    turtle turn left 90
    turtle forward s
    turtle turn left 90
    s = s * 0.97
    turtle turn left 10
    pause 10
  next i%
  font 3
  print @(425,282) "Nautilus"
  font 1
end sub

sub PlayIntro
  local i%,j%, x%, y%, tile%, blitdata%
  restore intro_data:
  for i% = 1 to 30
    for j% = 1 to 18
      read BlitData%
      x% = blitdata% and &HFF0000
      x% = x% >> 16
      y% = blitdata% and &H00FF00
      y% = y% >> 8
      tile% = blitdata% and &H0000FF
      blit tile% * 16, 0, x% * 16, y% * 16, 16, 16, 3
    next j%
  pause 100
  next i%
end sub

intro_data:
'    Seg. 1            Seg. 2            Seg. 3            Seg. 4            Seg. 5            Seg. 6            Seg. 7            Seg. 8            Seg 9
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H232401,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H17241b,&H000000,&H000000,&H000000,&H232302,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H17231a,&H000000,&H000000,&H000000,&H232203,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H172219,&H000000,&H000000,&H000000,&H232104,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H172118,&H000000,&H000000,&H000000,&H232005,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H172017,&H000000,&H000000,&H000000,&H231f06,&H000000,&H000000,&H000000,&H292410,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H171f16,&H000000,&H000000,&H000000,&H231e07,&H000000,&H000000,&H000000,&H292311,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H000000,&H000000,&H171e15,&H000000,&H000000,&H000000,&H231d08,&H000000,&H000000,&H000000,&H292212,&H000000,&H000000,&H000000
data &H000000,&H000000,&H000000,&H000000,&H11001c,&H000000,&H171d14,&H000000,&H000000,&H000000,&H231c09,&H000000,&H000000,&H000000,&H292113,&H000000,&H000000,&H000000
data &H000000,&H000000,&H0e0005,&H000000,&H11011b,&H000000,&H171c13,&H172400,&H000000,&H000000,&H231b0a,&H232400,&H000000,&H000000,&H292014,&H292400,&H000000,&H000000
data &H000000,&H000000,&H0e0106,&H000000,&H11021a,&H000000,&H171b12,&H172300,&H000000,&H000000,&H231a0b,&H232300,&H000000,&H000000,&H291f15,&H292300,&H000000,&H000000
data &H000000,&H000000,&H0e0207,&H000000,&H110319,&H000000,&H171a11,&H172200,&H000000,&H000000,&H23190c,&H232200,&H000000,&H000000,&H291e16,&H292200,&H000000,&H000000
data &H000000,&H000000,&H0e0308,&H000000,&H110418,&H000000,&H171910,&H172100,&H1f000f,&H000000,&H23180d,&H232100,&H000000,&H000000,&H291d17,&H292100,&H000000,&H000000
data &H000000,&H000000,&H0e0409,&H000000,&H110517,&H000000,&H17180f,&H172000,&H1f0110,&H000000,&H23170e,&H232000,&H250005,&H000000,&H291c18,&H292000,&H000000,&H000000
data &H000000,&H000000,&H0e050a,&H000000,&H110616,&H000000,&H17170e,&H171f00,&H1f0211,&H000000,&H23160f,&H231f00,&H250106,&H000000,&H291b19,&H291f00,&H000000,&H000000
data &H000000,&H000000,&H0e060b,&H000000,&H110715,&H000000,&H17160d,&H171e00,&H1f0312,&H000000,&H231510,&H231e00,&H250207,&H000000,&H291a1a,&H291e00,&H000000,&H000000
data &H000c0b,&H000000,&H0e070c,&H000000,&H110814,&H000000,&H17150c,&H171d00,&H1f0413,&H000000,&H231411,&H231d00,&H250308,&H000000,&H29191b,&H291d00,&H000000,&H000000
data &H010c0c,&H000000,&H0e080d,&H000000,&H110913,&H000000,&H17140b,&H171c00,&H1f0514,&H000000,&H231312,&H231c00,&H250409,&H000000,&H29181c,&H291c00,&H000000,&H000000
data &H020c0d,&H000000,&H0e090e,&H0e0000,&H110a12,&H110000,&H17130a,&H171b00,&H1f0615,&H1f0000,&H231213,&H231b00,&H25050a,&H000000,&H29171d,&H291b00,&H000000,&H000000
data &H030c0e,&H000000,&H0e0a0f,&H0e0100,&H110b11,&H110100,&H171209,&H171a00,&H1f0716,&H1f0100,&H231114,&H231a00,&H25060b,&H000000,&H29161e,&H291a00,&H310811,&H000000
data &H040c0f,&H000000,&H0e0b10,&H0e0200,&H110c10,&H110200,&H171108,&H171900,&H1f0817,&H1f0200,&H231015,&H231900,&H25070c,&H000000,&H29151f,&H291900,&H300810,&H000000
data &H050c10,&H000000,&H0e0c11,&H0e0300,&H110d0f,&H110300,&H171007,&H171800,&H1f0918,&H1f0300,&H230f16,&H231800,&H25080d,&H000000,&H291420,&H291800,&H2f080f,&H000000
data &H060c11,&H000c00,&H0e0d12,&H0e0400,&H110e0e,&H110400,&H170f06,&H171700,&H1f0a19,&H1f0400,&H230e17,&H231700,&H26080e,&H250000,&H291321,&H291700,&H2e080e,&H000000
data &H070c12,&H010c00,&H0e0e13,&H0e0500,&H110f0d,&H110500,&H170e05,&H171600,&H1f0b1a,&H1f0500,&H230d18,&H231600,&H26090f,&H250100,&H291222,&H291600,&H2d080d,&H310800
data &H080c13,&H020c00,&H0e0f14,&H0e0600,&H120f0c,&H110600,&H170d04,&H171500,&H1f0c1b,&H1f0600,&H230c19,&H231500,&H260a10,&H250200,&H291101,&H291500,&H2c080c,&H300800
data &H080d14,&H030c00,&H0d0f15,&H0e0700,&H130f0b,&H110700,&H170c03,&H171400,&H1e0c1c,&H1f0700,&H220c1a,&H231400,&H260b11,&H250300,&H291002,&H291400,&H2b080b,&H2f0800
data &H080e15,&H040c00,&H0c0f16,&H0e0800,&H140f0a,&H110800,&H180c02,&H171300,&H1d0c1d,&H1f0800,&H210c1b,&H231300,&H260c12,&H250400,&H290f03,&H291300,&H2a080a,&H2e0800
data &H080f16,&H050c00,&H0b0f17,&H0e0900,&H140e09,&H110900,&H190c01,&H171200,&H1d0d1e,&H1f0900,&H200c1c,&H231200,&H260d13,&H250500,&H290e04,&H291200,&H290809,&H2d0800
data &H090f17,&H060c00,&H0b0e18,&H0e0a00,&H140d08,&H110a00,&H1a0c22,&H171100,&H1d0e1f,&H1f0a00,&H200d1d,&H231100,&H260e14,&H250600,&H290d05,&H291100,&H290908,&H2c0800
data &H0a0f18,&H070c00,&H0b0d19,&H0e0b00,&H140c07,&H110b00,&H1a0d21,&H171000,&H1d0f20,&H1f0b00,&H200e1e,&H231000,&H260f15,&H250700,&H290c06,&H291000,&H2a0907,&H2b0800


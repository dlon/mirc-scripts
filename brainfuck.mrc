; simple encryption:
;   encode: /brainfuck >>>,[<<<+[>+>+<<-]>>[-<<+>>]<[->>+<<]>>.,] text
;   decode: /brainfuck >>>,[<<<+[>+>+<<-]>>[-<<+>>]<[->>-<<]>>.,] encoded text

alias brainfuck {
  var %i = 1, %loopref, %cur = 1
  var %input = $2-, %inputCur = 1
  bset &bfbuf 30000 0
  bset &outbuf 1 0
  ;var %dbginf = $true

  while (%i <= $len($1)) {
    var %ch = $mid($1,%i,1)
    if (%ch == $chr(91)) {
      ; [ begin loop
      if ($bvar(&bfbuf,%cur)) {
        %loopref = $addtok(%loopref, %i, 32)
        if (%dbginf) echo -a 3begin loop at %i
      }
      else {
        ; NOTE: $1
        var %temp = $pos($mid($1,%i,$len($1)), $chr(93), 1)
        if (%temp == $null) {
          echo -a 4Error: (E2) unclosed [ at %i
          return
        }
        if (%dbginf) echo -a 3skip loop from %i to %temp
        %i = %temp
      }
    }
    elseif (%ch == $chr(93)) {
      ; ] end loop
      ; get last '['
      var %loopS = $gettok(%loopref, -1, 32)
      if (%loopS == $null) {
        echo -a 4Error: token %ch at pos %i
        return
      }
      else {
        if ($bvar(&bfbuf,%cur) == 0) {
          %loopref = $deltok(%loopref, -1, 32)
          if (%dbginf) echo -a 3ended loop from %loopS to %i
        }
        else {
          if (%dbginf) echo -a 3repeat loop from %loopS to %i
          %i = %loopS
        }
      }
    }
    elseif (%ch == $chr(44)) {
      ; , read input
      var %readch = $mid(%input, %inputCur, 1)
      if (%readch == $null) {
        %readch = 0
      }
      else {
        %readch = $asc($mid(%input, %inputCur, 1))
      }
      bset &bfbuf %cur %readch
      inc %inputCur
    }
    elseif (%ch == $chr(46)) {
      ; . output
      ; FIX: output as binvar... for spaces' sake
      bset &outbuf $calc($bvar(&outbuf,0) + 1) $bvar(&bfbuf,%cur)
    }
    elseif (%ch == $chr(43)) {
      ; + increment *ptr (cur)
      ; FIXME: *cur == 255
      bset &bfbuf %cur $calc($bvar(&bfbuf,%cur) + 1)
    }
    elseif (%ch == $chr(45)) {
      ; - decrement *ptr (cur)
      ; FIXME: *cur == 0
      bset &bfbuf %cur $calc($bvar(&bfbuf,%cur) - 1)
    }
    elseif (%ch == $chr(62)) {
      ; > move ptr right (cur)
      ; FIXME: upperbound
      inc %cur
    }
    elseif (%ch == $chr(60)) {
      ; < move ptr left (cur)
      ; FIXME: what happens at cur < 1?
      if (%cur > 1) dec %cur
    }
    inc %i
  }
  while (%loopref != $null) {
    echo -a 4Error: unclosed [ at pos $gettok(%loopref, 1, 32)
    %loopref = $deltok(%loopref, 1, 32)
  }
  echo -a Output: $bvar(&outbuf,2,$calc($bvar(&outbuf,0) - 1)).text
}
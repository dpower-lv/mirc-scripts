; the nickserv setup alias - /nsSetup
alias nsSetup {
  ; if no arguments passed, display a help message
  if (!$1) {
    echo -a ** /nsSetup <network> [pass]
  }
  else {
  ; if no password was set, consider this as a request to disable ns authorization for this network
    if (!$2) {
      unset %ns. $+ $1 $+ .*
      set %ns. $+ $1 $+ .on $false
      echo -a ** Disabled for network $1
    }
    else {
      set %ns. $+ $1 $+ .on $true
      set %ns. $+ $1 $+ .pass $$2
      ; yes passwords are stored as a variable for now
      echo -a ** Enabled for network $1
    }
  }
}

; alias for ns recovery on ghost detection
alias nsRecover {
  if ($$1 && $nsEnabled($1)) {
    ; syntax may depend on the network (?)
    ns recover $mnick $nsPass($1)
  }
}

; this alias is used as an identifier $nsEnabled
; checks if ns auth is enabled for the network, whose name is passed as an argument
alias -l nsEnabled {
  return %ns. [ $+ [ $$1 ] $+ .on ]
}

; this alias is used as an identifier $nsPass
; gets ns password for the network, whose name is passed as an argument
alias -l nsPass {
  return %ns. [ $+ [ $$1 ] $+ .pass ]
}

; check for a ghost (raw 433) with the name same as the current main nick
raw 433:$(* $mnick *):{
  if (%ns. $+ $network $+ .on) {
    echo -a ** 8[NS] Ghost detected
    ; mark this nickname as the one in use
    set %ns. $+ $network $+ .inuse $true
    ; set a delay to recover the nick on this network
    .timer $+ $network 1 3 nsRecover $network
  }
}

; on notice parsing
on *:NOTICE:*This nickname is registered*:?:{
  ; check if it is nickserv sending this notice
  if ($nick == NickServ && $nsEnabled($network)) {
    echo -s [NS] 13Identifying as $mnick
    ns identify $nsPass($network)
  }
}

; check if nickserv killed the ghost
on *:NOTICE:*has been killed*:?:{
  if ($nick == NickServ && $nsEnabled($network)) {
    ; change the current nick back to the main nick and mark it as not in use
    nick $mnick
    set %ns. $+ $network $+ .inuse $false
  }
}

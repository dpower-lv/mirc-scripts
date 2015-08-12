alias nsSetup {
  if (!$1) {
    echo -a ** /nsSetup <network> [pass]
  }
  else {
    if (!$2) {
      unset %ns. $+ $1 $+ .*
      set %ns. $+ $1 $+ .on $false
      echo -a ** Disabled for network $1
    }
    else {
      set %ns. $+ $1 $+ .on $true
      set %ns. $+ $1 $+ .pass $$2
      echo -a ** Enabled for network $1
    }
  }
}

alias nsRecover {
  if ($$1 && $nsEnabled($1)) {
    ns recover $mnick $nsPass($1)
  }
}

alias -l nsEnabled {
  return %ns. [ $+ [ $$1 ] $+ .on ]
}

alias -l nsPass {
  return %ns. [ $+ [ $$1 ] $+ .pass ]
}

raw 433:$(* $mnick *):{
  if (%ns. $+ $network $+ .on) {
    echo -a ** 8[NS] Ghost detected
    set %ns. $+ $network $+ .inuse $true
    .timer $+ $network 1 3 nsRecover $network
  }
}

on *:NOTICE:*This nickname is registered*:?:{
  echo -s [NS] 13Identifying as $mnick
  if ($nick == NickServ && $nsEnabled($network)) {
    ns identify $nsPass($network)
  }
}

on *:NOTICE:*has been killed*:?:{
  if ($nick == NickServ && $nsEnabled($network)) {
    nick $mnick
    set %ns. $+ $network $+ .inuse $false
  }
}

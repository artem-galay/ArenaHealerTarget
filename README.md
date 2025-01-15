# ArenaHealerTarget
To install addon paste ArenaHealerTarget directory from this project to your World of Warcraft\_retail_\Interface\AddOns directory

## Ingame commands:

/aht - run Arena module manually

/ahtbg - run BG module manually

/ahthelp - help

This addon will detect enemies' healers and replace special marks in your macro with healers' arena units (when in Arena) or with healers' nicknames (when in BG).
Addon automatically starts when you entered Arena or BG (handling START_TIMER event). It will modify your macro 10 second before gates open.
To make it works create character-specific (in second macro tab) macro with special '!AHT*' prefix in its name (!AHTFear for example).
Addon will create new macro without '!AHT*' prefix in its name (!AHTFear -> Fear) or modify existed macro with that name.

## List of special marks for macro:
```
!ht - will be replaced with healer arena unit (for Arena match) or with 1st enemy healer's nickname (for BGs)
!1dd - will be replaced with 1st dps arena unit (for Arena match, unused in BGs)
!2dd - will be replaced with 2nd dps arena unit (for Arena match, unused in BGs)
!ft - will be replaced with constant 'focus' unit (for Arena match) or with 2nd enemy healer's nickname (for BGs)
```

## Macro example:
```
/tar [mod:shift] !ht; [mod:ctrl] !ft
/cast Fear
/targetlasttarget [mod:shift][mod:ctrl]
```

### After marks replacing when in ARENA will look like:
```
/tar [mod:shift] arena2; [mod:ctrl] focus
/cast Fear
/targetlasttarget [mod:shift][mod:ctrl]
```
Cast Fear to healer with SHIFT, to focus with CTRL, or to target without modifier.

### After marks replacing when in BG will look like:
```
/tar [mod:shift] Besthealereu-Doomahmmer; [mod:ctrl] Worsthealereu-Turalyon
/cast Fear
/targetlasttarget [mod:shift][mod:ctrl]
```
Cast Fear to healer1 with SHIFT, to healer2 with CTRL, or to target without modifier.

# CaffeineBar

A tiny macOS menu bar app that keeps the Mac awake without spawning `caffeinate`. It holds an IOKit power assertion (`kIOPMAssertPreventUserIdleSystemSleep`) directly — the display can still sleep, but the system won't.

Left-click the coffee cup icon to toggle on/off. Right-click for the menu (state, Launch at Login, Quit).

## Build

```
./build.sh
```

Produces `build/CaffeineBar.app`.

## Install

```
./build.sh install
```

Copies the app to `/Applications/CaffeineBar.app`. Then run:

```
open /Applications/CaffeineBar.app
```

## Uninstall

1. Open the menu and turn off "Launch at Login" if it's on.
2. Quit the app.
3. `rm -rf /Applications/CaffeineBar.app`

## Verify the assertion is active

```
pmset -g assertions | grep -i PreventUserIdleSystemSleep
```

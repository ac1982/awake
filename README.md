# awake

Block the screen saver and auto-lock while automation drives your Mac.

Anything that drives the GUI — a computer-use agent, a long scripted run, a
remote demo — breaks the moment macOS locks the screen. `loginwindow` takes
over, so screenshots stop seeing your session and synthetic clicks go nowhere.

`awake` holds the relevant power assertions for exactly as long as you ask it
to, then releases them. **It changes no system settings.** Your screen saver
and lock preferences stay exactly as you left them, which means the protection
is scoped to the run instead of left switched on forever.

```
  awake · staying awake for 2h
  screen saver and auto-lock paused  ·  Ctrl-C to stop

  ●  1:59:42  ━━━━━━━━━━━──────────────────
```

That dot breathes. It is a 4-second sine curve between a dim and a bright cyan,
gamma-corrected so it lingers in the dark half — a linear ramp reads as a
tug-of-war rather than breathing.

## Install

```sh
git clone https://github.com/ac1982/awake.git
cd awake
ln -s "$PWD/awake" ~/.local/bin/awake    # any directory on your PATH
```

Requires zsh (macOS ships it) and nothing else outside the base system:
`caffeinate`, `pgrep`, `pmset`, `ps`, `nohup`.

## Usage

```
awake            stay awake for 8 hours, Ctrl-C to stop
awake 2h         stay awake for 2 hours (also 1h30m / 90m / 45s / 5400)
awake -b 2h      run in the background, terminal can be closed
awake -- cmd…    stay awake while the command runs, passing its exit code
awake -w 1234    stay awake until pid 1234 exits (the duration is a ceiling, 8h by default)
awake status     show running instances and how long they have held
awake off        stop every instance, including ones in other terminals
```

Durations are written largest unit first, each unit at most once: `2h`,
`1h30m`, `2m30s`, or a bare number of seconds. That is exactly the form awake
prints, so any duration it shows you can be typed back in.

### Tie it to the automation, not a guess

A fixed duration is a guess: too long and the Mac stays unlockable for hours
after the run ends, too short and it locks mid-run. Hand awake the run itself
instead and the hold ends the moment the run does:

```sh
awake -- python agent.py        # held while the command runs
awake 3h -w "$(pgrep -n node)"  # held until an already-running process exits
```

The duration still applies, as a ceiling: a hung process cannot keep the Mac
unlockable forever. With `--`, awake stays out of the command's way. It prints
one line to stderr before and one after, passes the command's exit code
through, and leaves Ctrl-C to the command, so a program that handles Ctrl-C
itself keeps its protection. If awake is killed outright, `caffeinate` notices
and releases the hold anyway.

`status` reports what is actually held, not what was requested:

```
  ●  awake is running · 1 instance

     pid 16531   held for 05:41      ttys002

     ✓ PreventUserIdleDisplaySleep
     ✓ UserIsActive

     stop with: awake off
```

When nothing is running it reads your real screen saver setting, so it tells
you what will actually happen rather than a hardcoded guess:

```
  ○  awake is not running
     screen saver starts after 3 min
```

## How it works

One `caffeinate -disu -t <seconds>`, plus `-w <pid>` when there is a process
to wait for:

| flag | effect |
| --- | --- |
| `-d` | blocks display sleep, and with it the screen saver |
| `-i` | blocks idle system sleep |
| `-s` | blocks sleep while on AC power |
| `-u` | asserts "user is active", so the idle timer never accumulates |
| `-w` | releases early when the given process exits |

`-d` alone stops the display from sleeping but the screen saver has its own
idle timer, and a screen saver is nearly as bad as a lock for automation: the
first synthetic click gets spent dismissing it. `-u` is what keeps that timer
from ever building up.

Instances are tracked by their command line rather than a pidfile. A pidfile
only remembers the last one started, so an instance launched in another
terminal becomes unreachable — `awake off` would silently miss it.
Only your own instances count; another user's are not yours to stop.

Starting a second instance while one is running is allowed. Assertions stack,
so it is harmless, and the running one may be something in active use
elsewhere; killing it to be tidy would be the unhelpful move. You get a warning
instead.

## Language

The UI follows your Mac's language (English and Simplified Chinese are
included). It reads `AppleLanguages` first, because on macOS `LANG` is usually
whatever the terminal emulator decided and says nothing about what you picked
in System Settings. Override with `AWAKE_LANG=en` or `AWAKE_LANG=zh`.

## Terminal behavior

| environment | result |
| --- | --- |
| truecolor terminal | 24-bit breathing gradient, 20fps |
| 256-color terminal | cyan ramp breathing |
| `NO_COLOR=1` | static dot, progress bar still moves, 2fps |
| piped or redirected | one line of plain text, zero escape codes |
| narrower than 58 columns | progress bar shrinks, minimum 8 cells |

The animation loop is built entirely from zsh builtins and forks zero times per
frame. Command substitution would fork: measured at 3000 substitutions in 1.48s
versus 3000 `printf -v` in 0.003s, which over an 8-hour run at 20fps is the
difference between seconds of CPU and a quarter hour of it.

Elapsed and remaining use different line weights rather than only color, so the
bar stays readable under a low-contrast theme or `NO_COLOR`.

## What it does not do

- **Manual locks.** ⌃⌘Q still locks immediately, by design.
- **Closing the lid.** `caffeinate` cannot block clamshell sleep.
- **Anything permanent.** Nothing is written to disk or to your settings. If
  you forget to start it, the Mac locks on its normal schedule.

If you want automation to survive a locked host, run it in a VM or a container
with a virtual display instead — the host can lock all it likes.

## License

MIT

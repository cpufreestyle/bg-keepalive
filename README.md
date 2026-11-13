# Background Keepalive

KernelSU / Magisk module for rooted Android 11+ devices. It keeps a short list of
apps alive in the background and puts back accessibility services that the system
silently drops after a reboot, a crash, or a low-memory kill.

Written for a Galaxy S25 Ultra running One UI, but nothing in it is Samsung
specific: the package list is just a shell variable.

## What it actually does

Every 3 minutes the loop runs two passes.

**Background exemption.** For each package in `PKG_LIST` it applies:

- `cmd deviceidle whitelist +<pkg>` — survive Doze
- `am set-standby-bucket <pkg> active` — never be bucketed as rare
- `appops set <pkg> RUN_ANY_IN_BACKGROUND allow`
- `appops set <pkg> RUN_IN_BACKGROUND allow`

**Accessibility repair.** For each `pkg/service` pair in `A11Y_LIST` it reads
`settings get secure enabled_accessibility_services`. If the entry is missing it
appends it and re-applies `accessibility_enabled=1`; if the entry is already
there it does nothing.

That second half is the point of the module. Blindly rewriting the setting every
cycle makes Android tear down and rebuild every service each time, which is why
naive "keep accessibility alive" scripts cause visible stutter and input lag.
This one only touches the setting when something is genuinely gone.

## Install

Download the zip from [Releases](../../releases) and install it from the
KernelSU or Magisk module manager. Reboot.

`service.sh` is executed by init at `late_start`, so the loop comes back on its
own after every boot. There is no app, no UI and no daemon beyond one `sh`.

### Add it as a repository

The repo also ships a `modules.json`, so KernelSU Manager can list it like a
store entry. Add this URL as a custom source:

```
https://raw.githubusercontent.com/cpufreestyle/bg-keepalive/main/modules.json
```

## Configure

Edit the block at the top of `service.sh`:

```sh
PKG_LIST="li.songe.gkd com.x8bit.bitwarden com.notch.touch ..."
A11Y_LIST="com.notch.touch/com.notch.touch.lock.tas ..."
INTERVAL=180          # seconds between passes
```

`A11Y_LIST` entries must be `package/fully.qualified.ServiceClass`. The class
name is what `dumpsys accessibility` reports, not the one in the app's
manifest label.

Reinstall or reboot after editing — the running loop keeps its own copy.

## Logs and control

```sh
tail -f /data/local/tmp/bg_keepalive.log   # actions only, not every pass
touch /data/local/tmp/bg_keepalive.stop    # ask the loop to exit
cat /data/local/tmp/bg_keepalive.pid       # current pid
```

The log rotates itself at 64 KB. A quiet log is the normal state: entries
appear only when something needed repair or a package went missing.

## Uninstall

Remove the module and reboot. Nothing outside `/data/adb/modules/bg_keepalive`
and `/data/local/tmp/bg_keepalive.*` is modified, so the device is clean once
those are gone. Accessibility entries added by the module are left in place;
disable the services in Settings if you want them gone.

## Caveats

- Root is required. This will not work on a stock device.
- Some apps detect accessibility services and refuse to run. That is on the app,
  not the module, and no script can hide a service it needs.
- The loop is a shell script, not a service with a watchdog. If it dies the
  module logs nothing until the next reboot.

## License

MIT. See [LICENSE](LICENSE).

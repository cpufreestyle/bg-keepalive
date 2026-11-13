# Changelog

## v3.3

- Package as a flashable zip (META-INF + customize.sh) for KernelSU and Magisk.
- Add `updateJson` so module managers can show new versions.
- Unchanged runtime behaviour: 3-minute sweep, repair only what broke.

## v3.2

- Skip services that already have a live binding, so the sweep no longer
  rebinds healthy accessibility services every cycle.
- Keep the state directory so repeated failures back off instead of looping.

## v3.1

- Add Bitwarden, Sunlogin, UU Remote, RustDesk and HoneyPlayPlus to the
  background-exempt list.

## v3.0

- First version: doze whitelist, standby bucket, background appops and
  accessibility rebind loop for notch.touch and GKD.

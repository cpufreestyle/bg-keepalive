# Changelog

## v3.5

- Read the module version with `sed` instead of `grep -m1`, which toybox on
  One UI 9 does not accept.
- Probe `RUN_ANY_IN_BACKGROUND` once at startup and skip it when the ROM
  rejects the op, so Samsung devices stop logging an error per package per sweep.
- No change to the 3-minute sweep or to which apps are exempted.

## v3.4

- Do not abort the install when the module manager does not export `API`;
  the Android 11 check now only runs when the value is present.
- No runtime behaviour change.

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

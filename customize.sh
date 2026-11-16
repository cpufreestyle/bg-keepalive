#!/system/bin/sh
# KernelSU / Magisk install hook.

SKIPUNZIP=0

ui_print "- Background Keepalive"
ui_print "- author: michaelqiu"

# Managers that do not export API would make `[ "$API" -lt 30 ]` fail with
# "integer expression expected" and abort the install, so only check when set.
if [ -n "$API" ] && [ "$API" -lt 30 ]; then
  abort "! Android 11 or newer is required (API $API found)"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- installed to $MODPATH, reboot to activate"

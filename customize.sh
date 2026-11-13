#!/system/bin/sh
# KernelSU / Magisk install hook.

SKIPUNZIP=0

ui_print "- Background Keepalive"
ui_print "- author: michaelqiu"

if [ "$API" -lt 30 ]; then
  abort "! Android 11 or newer is required (API $API found)"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- installed to $MODPATH, reboot to activate"

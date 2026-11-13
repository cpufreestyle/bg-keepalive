#!/system/bin/sh
# Background keepalive + accessibility auto-rebind (KernelSU service.sh, runs as root).
MODDIR=/data/adb/modules/bg_keepalive
PKG_LIST="li.songe.gkd com.x8bit.bitwarden com.notch.touch ginlemon.flowerfree com.oray.sunlogin.service com.netease.uuremote com.carriez.flutter_hbb"
A11Y_LIST="com.notch.touch/com.notch.touch.lock.tas li.songe.gkd/com.google.android.accessibility.selecttospeak.SelectToSpeakService com.oray.sunlogin.service/com.oray.sunlogin.service.PermissionAccessibilityService com.netease.uuremote/com.remote.provider.service.UURemoteAccessibilityService com.carriez.flutter_hbb/com.carriez.flutter_hbb.InputService com.samsung.android.game.honeyplayplus/com.samsung.android.game.honeyplayplus.gamepad.touchmapping.dialog.DialogDetectionAccessibilityService"
LOG=/data/local/tmp/bg_keepalive.log
STOP=/data/local/tmp/bg_keepalive.stop
PIDF=/data/local/tmp/bg_keepalive.pid
STATED=/data/local/tmp/bg_keepalive.state
INTERVAL=180
MAXFAIL=5

say() {
  echo "$(date '+%F %T') $*" >> "$LOG"
  sz=$(wc -c < "$LOG" 2>/dev/null)
  [ -n "$sz" ] && [ "$sz" -gt 65536 ] && { tail -c 32768 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; }
}

pkg_of() { echo "$1" | cut -d/ -f1; }

fails() { cat "$STATED/$1.count" 2>/dev/null || echo 0; }
set_fails() { mkdir -p "$STATED"; echo "$2" > "$STATED/$1.count"; }

assert_pkgs() {
  for p in $PKG_LIST; do
    cmd deviceidle whitelist +"$p" >/dev/null 2>&1
    am set-standby-bucket "$p" active >/dev/null 2>&1
    appops set "$p" RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1
    appops set "$p" RUN_IN_BACKGROUND allow >/dev/null 2>&1
  done
}

assert_never_sleeping() {
  nsp=$(settings get global never_sleeping_packages)
  [ "$nsp" = "null" ] && nsp=
  out=""
  for it in $(echo "$nsp" | tr ',' ' ') $PKG_LIST; do
    case " $out " in *" $it "*) ;; *) out="$out $it" ;; esac
  done
  val=""
  for it in $out; do val="$val,$it"; done
  settings put global never_sleeping_packages "$val,"
}

crash_evidence() {
  pk=$1
  for f in $(ls -t /data/system/dropbox/ 2>/dev/null | head -8); do
    if grep -q "Process: $pk$" "/data/system/dropbox/$f" 2>/dev/null; then
      say "crash log: /data/system/dropbox/$f"
      sed -n '1,12p;/^java\./,^\tat /p' "/data/system/dropbox/$f" 2>/dev/null | head -30 >> "$LOG"
      return 0
    fi
  done
  say "no dropbox entry for $pk, falling back to logcat"
  logcat -b crash,main -d 2>/dev/null | grep -E "$pk|AndroidRuntime|FATAL|accessibility" | tail -40 >> "$LOG"
}

rebind() {
  comp=$1
  cur=$(settings get secure enabled_accessibility_services)
  [ "$cur" = "null" ] && cur=
  stripped=$(echo ":$cur:" | sed "s#:$comp:#:#g" | sed 's/^://; s/:$//')
  settings put secure enabled_accessibility_services "$stripped"
  sleep 2
  if [ -n "$stripped" ]; then new="$stripped:$comp"; else new="$comp"; fi
  settings put secure enabled_accessibility_services "$new"
  settings put secure accessibility_enabled 1
  sleep 4
}

guard_a11y() {
  enabled=$(settings get secure enabled_accessibility_services)
  for comp in $A11Y_LIST; do
    case ":$enabled:" in
      *":$comp:"*)
        set_fails "$comp" 0
        continue
        ;;
    esac
    n=$(fails "$comp")
    if [ "$n" -ge "$MAXFAIL" ]; then
      continue
    fi
    say "$comp missing; rebind attempt $((n+1))/$MAXFAIL"
    rebind "$comp"
    enabled=$(settings get secure enabled_accessibility_services)
    case ":$enabled:" in
      *":$comp:"*)
        say "$comp repaired"
        set_fails "$comp" 0
        ;;
      *)
        set_fails "$comp" $((n+1))
        say "$comp still missing after $((n+1))/$MAXFAIL attempts"
        ;;
    esac
  done
}

if [ -f "$PIDF" ]; then
  old=$(cat "$PIDF")
  [ -n "$old" ] && kill -0 "$old" 2>/dev/null && exit 0
fi
echo $$ > "$PIDF"

say "start v3.2 pid=$$"
assert_pkgs
assert_never_sleeping
guard_a11y
say "boot pass done"

while :; do
  sleep "$INTERVAL"
  [ -f "$STOP" ] && { say "stop flag"; break; }
  [ -d "$MODDIR" ] || { say "module removed"; break; }
  assert_pkgs
  guard_a11y
done
rm -f "$PIDF"

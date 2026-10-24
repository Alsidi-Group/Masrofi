#!/usr/bin/env bash
# ============================================================
#  verify-release.sh — الفحص المستمر لسلامة إصدار مصروفي
#  الاستخدام:  bash verify-release.sh [مجلد الحزمة]
#  افتراضياً يفحص المجلد الحالي. أكواد الخروج:
#    0 = كل الفحوصات ناجحة    1 = فشل فحص واحد على الأقل
# ============================================================
set -u
PKG="${1:-.}"
cd "$PKG" 2>/dev/null || { echo "✗ المجلد غير موجود: $PKG"; exit 1; }

VER="1.9.8"
CODE="21"
APK="Masrofi-v${VER}.apk"
DEC="Masrofi-apktool-decoded.zip"
SDK="${ANDROID_BUILD_TOOLS:-}"   # يمكن تمرير مسار build-tools هنا
PASS=0; FAIL=0
ok(){ echo "  ✓ $1"; PASS=$((PASS+1)); }
bad(){ echo "  ✗ $1"; FAIL=$((FAIL+1)); }
find_tool(){ # apksigner / aapt / zipalign
  local t="$1"
  if [ -n "$SDK" ] && [ -x "$SDK/$t" ]; then echo "$SDK/$t"; return 0; fi
  local p
  for p in /home/z/my-project/android/sdk/android-14 "$HOME/Android/Sdk/build-tools/"* /opt/android-sdk/build-tools/* /usr/lib/android-sdk/build-tools/*; do
    [ -x "$p/$t" ] && { echo "$p/$t"; return 0; }
  done
  return 1
}

echo "══════════════════════════════════════════"
echo " فحص إصدار مصروفي v${VER} (code ${CODE})"
echo " المجلد: $(pwd)"
echo "══════════════════════════════════════════"

# 1) وجود الملفات الأساسية
echo "[1/6] وجود ملفات الحزمة"
for f in "$APK" "$DEC" "update.json" "index.html" "SHA256SUMS.txt" "verify-release.sh" "build-release.sh"; do
  [ -s "$f" ] && ok "$f" || bad "مفقود أو فارغ: $f"
done

# 2) البصمات مقابل SHA256SUMS.txt
echo "[2/6] بصمات SHA-256"
if command -v sha256sum >/dev/null 2>&1 && [ -f SHA256SUMS.txt ]; then
  if sha256sum -c SHA256SUMS.txt --quiet 2>/dev/null; then ok "كل البصمات مطابقة لـ SHA256SUMS.txt"
  else bad "عدم تطابق بصمة — أعد توليد SHA256SUMS.txt أو أعد التحميل"; fi
else
  bad "sha256sum غير متوفر أو SHA256SUMS.txt مفقود"
fi

# 3) توقيع الـ APK
echo "[3/6] توقيع APK"
APKSIGNER="$(find_tool apksigner || true)"
if [ -n "${APKSIGNER:-}" ] && [ -x "${APKSIGNER:-}" ]; then
  if "$APKSIGNER" verify "$APK" >/dev/null 2>&1; then
    ok "التوقيع سليم apksigner verify"
    CERT="$("$APKSIGNER" verify --print-certs "$APK" 2>/dev/null | rg -o 'SHA-256 digest: [0-9a-f]+' | head -1 | cut -d' ' -f3)"
    [ "$CERT" = "abcc93eb60ec8042822eb4b162dbf3f20a11293644bd1d9f0731dd9a76becb97" ] \
      && ok "شهادة مصروفي المعروفة (abcc93eb…)" || bad "الشهادة غير المتوقعة: ${CERT:-؟}"
  else
    bad "فشل apksigner verify — APK غير موقّع أو تالف"
  fi
else
  echo "  ⚠ apksigner غير متوفر — تخطّي فحص التوقيع (اضبط ANDROID_BUILD_TOOLS)"
fi

# 4) badging: الحزمة والإصدار
echo "[4/6] بيانات الحزمة والإصدار"
AAPT="$(find_tool aapt || true)"
if [ -n "${AAPT:-}" ] && [ -x "${AAPT:-}" ]; then
  B="$("$AAPT" dump badging "$APK" 2>/dev/null | head -3)"
  echo "$B" | rg -q "package: name='com.marwanalsidi.masrofi' versionCode='${CODE}' versionName='${VER}'" \
    && ok "com.marwanalsidi.masrofi — v${VER} (code ${CODE})" || bad "badging لا يطابق v${VER}/code ${CODE}"
else
  echo "  ⚠ aapt غير متوفر — تخطّي فحص badging"
fi

# 5) اتساق update.json
echo "[5/6] اتساق update.json"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$VER" "$APK" "$CODE" <<'PY' && ok "update.json: versionName/versionCode/apkUrl متسقة" || bad "update.json غير متسق"
import json,sys
ver,apk=sys.argv[1],sys.argv[2]
d=json.load(open("update.json"))
assert d["versionName"]==ver and str(d["versionCode"])==sys.argv[3], "version mismatch"
assert d["apkUrl"].rstrip("/").endswith(apk), f"apkUrl لا يشير إلى {apk}"
PY
else
  bad "python3 غير متوفر"
fi

# 6) الصفحة مكتفية ذاتياً وتشير للإصدار
echo "[6/6] صفحة index.html"
rg -q 'Masrofi-v'"${VER}"'\.apk' index.html && ok "زر التحميل يشير إلى $APK" || bad "index.html لا تشير إلى $APK"
if rg -qo 'src="https?://|href="https?://(?!github\.com/Alsidi-Group)' index.html --pcre2 2>/dev/null; then
  bad "index.html تحوي موارد خارجية (غير مكتفية ذاتياً)"
else
  ok "لا موارد خارجية — مكتفية ذاتياً"
fi

echo "══════════════════════════════════════════"
echo " النتيجة: ✓ ${PASS} ناجح   ✗ ${FAIL} فاشل"
[ "$FAIL" -eq 0 ] && { echo " الإصدار v${VER} جاهز للنشر والتحميل المباشر."; exit 0; }
echo " صحّح البنود الفاشلة أعلاه ثم أعد الفحص."
exit 1

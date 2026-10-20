#!/usr/bin/env bash
# ============================================================
#  build-release.sh — بناء وتوقيع إصدار مصروفي من المشروع المفكوك
#  الاستخدام:  bash build-release.sh
#  المتطلبات: java (JDK 17+) + apktool.jar + build-tools (aapt/apksigner/zipalign)
#  لإصدار نسخة جديدة: عدّل VER و VERSION_CODE أدناه فقط، ثم عدّل
#  versionCode/versionName في decoded/apktool.yml — أو مرّرها كوسيطتين:
#      bash build-release.sh 1.8.0 11
# ============================================================
set -euo pipefail

# -------- إعدادات الإصدار (المصدر الوحيد للحقيقة) --------
VER="1.7.0"            # versionName
VERSION_CODE="10"      # versionCode
ALIAS="masrofi"
KS_PASS='Masrofi@2026'
# ---------------------------------------------------------

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${SRC:-$HERE/decoded-v${VER}}"
SDK="${ANDROID_BUILD_TOOLS:-/home/z/my-project/android/sdk/android-14}"
APKTOOL="${APKTOOL:-/home/z/my-project/android-build/apktool.jar}"
KS="${KS:-/home/z/my-project/android-build/masrofi.keystore}"
OUT="$HERE/Masrofi-v${VER}.apk"

echo "── بناء مصروفي v${VER} (versionCode ${VERSION_CODE})"

# 0) أدوات
for t in aapt apksigner zipalign; do
  [ -x "$SDK/$t" ] || { echo "✗ أداة ناقصة: $SDK/$t"; exit 1; }
done
[ -f "$APKTOOL" ] || { echo "✗ apktool.jar غير موجود: $APKTOOL"; exit 1; }
[ -f "$KS" ] || { echo "✗ مفتاح التوقيع غير موجود: $KS"; exit 1; }
[ -d "$SRC" ] || { echo "✗ مجلد المشروع المفكوك غير موجود: $SRC (فك Masrofi-apktool-decoded.zip أولاً)"; exit 1; }

# 1) ضمان مطابقة apktool.yml لأرقام الإصدار المعرفة أعلاه
python3 - "$SRC/apktool.yml" "$VER" "$VERSION_CODE" <<'PY'
import re,sys
p,ver,code=sys.argv[1],sys.argv[2],sys.argv[3]
s=open(p).read()
s=re.sub(r"versionCode: \d+",f"versionCode: {code}",s)
s=re.sub(r"versionName: ['\"]?[\d.]+['\"]?",f"versionName: '{ver}'",s)
open(p,"w").write(s)
PY
echo "  ✓ apktool.yml ← versionCode ${VERSION_CODE} / versionName ${VER}"

# 2) البناء
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
java -jar "$APKTOOL" b "$SRC" -o "$TMP/unsigned.apk" --use-aapt2 >/dev/null
echo "  ✓ apktool b — بناء ناجح"

# 3) المحاذاة ثم التوقيع
"$SDK/zipalign" -f -p 4 "$TMP/unsigned.apk" "$TMP/aligned.apk"
"$SDK/apksigner" sign --ks "$KS" --ks-key-alias "$ALIAS" \
  --ks-pass "pass:${KS_PASS}" --key-pass "pass:${KS_PASS}" \
  --out "$OUT" "$TMP/aligned.apk"
echo "  ✓ التوقيع: $KS (alias ${ALIAS})"

# 4) تحقق نهائي
"$SDK/apksigner" verify "$OUT"
"$SDK/aapt" dump badging "$OUT" | head -1 | sed 's/^/  ✓ /'
sha256sum "$OUT" | sed 's/^/  SHA256 /'

# 5) تجديد البصمات وصفحة التحميل تلقائياً بعد كل إصدار
cd "$HERE"
sha256sum "Masrofi-v${VER}.apk" "Masrofi-apktool-decoded.zip" "update.json" "index.html" > SHA256SUMS.txt 2>/dev/null || true
echo "── تم: $OUT جاهز للتحميل المباشر"
echo "  لا تنسَ: حدّث versionName/versionCode/apkUrl في update.json ليتطابق مع الإصدار الجديد."

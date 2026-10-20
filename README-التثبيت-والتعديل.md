# مصروفي v1.7.0 — دليل التثبيت والتعديل

**المطوّر:** مروان السيدي — Marwan Alsidi (ليبيا) • Alsidi Group
**الحزمة:** `com.marwanalsidi.masrofi` • versionCode **10** • versionName **1.7.0**

---

## ■ ما الجديد في v1.7.0

- **إصلاح حرج لفحص التحديثات:** رابط التحديث في الإصدارات السابقة كان يحمل توكناً شخصياً منتهياً، ما جعل كل المستخدمين لا يستلمون أي إشعار تحديث. الرابط الآن عام ونظيف مع مصدرين احتياطيين (GitHub raw ثم jsDelivr CDN).
- **استئناف سلسلة الإصدارات:** versionCode عاد للتصاعد (10 بعد 9)، متطابقاً مع وعد `update.json` في المستودع.
- لا تغييرات على الوظائف أو الواجهة: 13 لغة، 10 مظاهر، 28 عملة، طرق دفع ليبية، كل شيء كما في v1.6.0.

## ■ محتويات الحزمة

| الملف | الوصف |
|---|---|
| `Masrofi-v1.7.0.apk` | التطبيق الجاهز للتثبيت (موقّع، 340 KB تقريباً) |
| `Masrofi-apktool-decoded.zip` | المشروع مفكوكاً بالكامل (Smali + الموارد + AndroidManifest) |
| `update.json` | نموذج فحص التحديثات داخل التطبيق (versionCode 10 / versionName 1.7.0) |
| `index.html` | صفحة تحميل عربية أنيقة **مكتفة ذاتياً** — تعمل دون إنترنت |
| `build-release.sh` | سكربت البناء والتوقيع الآلي (VER=1.7.0 / VERSION_CODE=10 أعلى السكربت) |
| `verify-release.sh` | سكربت الفحص المستمر: ملفات + بصمات + توقيع + badging + اتساق update.json |
| `SHA256SUMS.txt` | بصمات SHA-256 لكل ملفات الحزمة |

## ■ مواصفات التطبيق

- الحزمة: `com.marwanalsidi.masrofi`
- الحد الأدنى: Android 11 (API 30) — الهدف: Android 14 (API 34)
- قاعدة البيانات: SQLite محلية بالكامل — لا يرسل أي بيانات للخارج
- كلمات المرور: SHA-256 مع Salt عشوائي لكل مستخدم
- الاتصال الوحيد بالإنترنت: فحص الإصدار عبر `update.json`

## ⚠ تنبيه التوقيع — اقرأه قبل التثبيت

مفتاح توقيع v1.6.0 فُقد مع بيئة البناء القديمة، فبُني هذا الإصدار بمفتاح جديد بنفس الاسم وكلمة السر الموثقة. النتيجة:

- **من لديه v1.4.0 – v1.6.0:** أندرويد سيرفض التثبيت فوق القديم. **احذف الإصدار القديم أولاً**، وصدّر إيصالاتك من داخل التطبيق قبل الحذف (قاعدة البيانات محلية وتُحذف مع التطبيق).
- **بصمة الشهادة الجديدة (Cert SHA-256):**
  `abcc93eb60ec8042822eb4b162dbf3f20a11293644bd1d9f0731dd9a76becb97`
- **بصمة APK ‏v1.7.0 (ملف SHA-256):**
  `db0cc2ef6c02a0040e06ccbb5a235be2fd10dad755736ca0ed84eddb10e0795e`

## ■ التثبيت على الهاتف

1. انقل `Masrofi-v1.7.0.apk` إلى الهاتف وافتحه.
2. فعّل «التثبيت من مصادر غير معروفة» إن طُلب منك.
3. إن كان لديك إصدار سابق: احذفه أولاً (بعد تصدير الإيصالات).
4. أنشئ حساباً محلياً أو اختر Gmail، ثم أضف راتبك وابدأ.

## ■ التثبيت عبر ADB (للمطورين)

```bash
adb install -r Masrofi-v1.7.0.apk
# بعد حذف إصدار قديم بتوقيع مختلف:
adb uninstall com.marwanalsidi.masrofi
adb install Masrofi-v1.7.0.apk
```

## ■ التحقق من سلامة الملفات

```bash
# فحص شامل بضغطة واحدة (يُفحص كل شيء ويطبع تقريراً):
bash verify-release.sh

# فحص يدوي للبصمة:
sha256sum -c SHA256SUMS.txt

# فحص التوقيع والشهادة:
apksigner verify --print-certs Masrofi-v1.7.0.apk
```

سكربت `verify-release.sh` يتحقق من: وجود الملفات السبعة، مطابقة البصمات، صلاحية التوقيع، تطابق الشهادة مع البصمة المعروفة، badging الحزمة والإصدار، اتساق `update.json`، واكتمال `index.html` — بأكواد خروج مناسبة للاستخدام في CI.

## ■ التعديل وإعادة البناء (apktool)

1. فك الحزمة: `unzip Masrofi-apktool-decoded.zip` → مجلد `decoded-v1.7.0/`
2. أشهر التعديلات:
   - الألوان والمظاهر: `decoded-v1.7.0/res/values/colors.xml`
   - النصوص وروابط التحديث: `decoded-v1.7.0/res/values/strings.xml`
   - الأيقونة: استبدل `res/mipmap-*/ic_launcher.png`
3. **أو استخدم السكربت الجاهز** (يبني، يحاذي، يوقّع، يتحقق، يجدد البصمات):

```bash
bash build-release.sh              # يبني v1.7.0 (code 10) كما هي مضبوطة
bash build-release.sh 1.8.0 11     # إصدار جديد: يرقّع apktool.yml تلقائياً
```

4. متطلبات البناء: JDK 17+، ‏`apktool.jar`، ‏build-tools فيها `aapt`/`apksigner`/`zipalign`
   (المسارات قابلة للتغيير عبر متغيرات البيئة `ANDROID_BUILD_TOOLS` و`APKTOOL` و`KS`).
5. مفتاح التوقيع `masrofi.keystore` — alias: `masrofi`، كلمة السر: `Masrofi@2026`
   ⚠ احفظ نسخة من هذا الملف في مكان آمن؛ فقدانُه يعني توقيع كل الإصدارات القادمة بمفتاح آخر وحذفَ التطبيق عند المستخدمين مرة أخرى.

## ■ النشر وروابط التحميل المباشر

1. ارفع ملفات هذه الحزمة إلى جذر المستودع `Alsidi-Group/Masrofi` (فرع main):
   `Masrofi-v1.7.0.apk` + `update.json` + `index.html`
2. يصبح التحميل المباشر متاحاً على:
   `https://github.com/Alsidi-Group/Masrofi/raw/main/Masrofi-v1.7.0.apk`
3. تطبيق v1.7.0 سيرى التحديثات القادمة تلقائياً عبر `update.json` على GitHub.
4. إصدار GitHub Release رسمي اختياري: Attach the APK → وسم `v1.7.0`.
5. يمكنك أيضاً استضافة `index.html` وAPK على أي استضافة ثابتة (GitHub Pages مثلاً) — الصفحة مكتفة ذاتياً وتعمل كما هي.

## ■ ملاحظة أمنية (مهمة للسجل)

تم اكتشاف توكن GitHub شخصي في `res/values/strings.xml` لإصدار v1.6.0 المنشور (`update_url?token=GHSAT0…`). **التوكن منتهٍ** لكن يُستحسن إلغاؤه نهائياً من إعدادات حساب GitHub إن لم يكن ملغى. في v1.7.0 أُزيل من **كل** ملفات اللغات، والروابط الآن عامة:
`https://raw.githubusercontent.com/Alsidi-Group/Masrofi/refs/heads/main/update.json`
احتياطياً: `…/Masrofi/main/update.json` و `https://cdn.jsdelivr.net/gh/Alsidi-Group/Masrofi@main/update.json`

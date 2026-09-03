# قائمة سد فجوات تطبيق الهاتف المحمول

> تاريخ الإنشاء: 2026-08-16 · المصدر: pmp-team ci-agent (P3-③ جرد الوضع الحالي، للقراءة فقط)
> خريطة الطريق المقابلة: docs/PROJECT_PLAN.md P3 — "توسيع صفحات HarmonyOS السبع إلى المسارات الأساسية (الدفع/الإصلاح/الإعلان/الزوار/المواقف)، وتكييف Flutter بوابة الملاك للجوال"

## أولاً: الوضع الحالي لتطبيق HarmonyOS للملاك (apps/harmonyos، 7 صفحات)

| الصفحة | المسار (مسجل في main_pages.json) | واجهة API المستدعاة |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | تسجيل الدخول (AuthService) |
| HomePage | pages/HomePage | GET /service/v1/home (لوحة القيادة: المبالغ المستحقة/الطلبات/عدد العقارات + قائمة الإعلانات) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**وضع التنقل الحالي** (4 انتقالات فقط في التطبيق كله): Login←Home、Home←Login (خروج)、Profile←Login、RepairList←RepairSubmit. تحتوي HomePage على بطاقات إحصائية + قائمة إعلانات فقط، دون شبكة مداخل وظيفية؛ صفحات FeeBills/Announcement/Profile موجودة لكن **بلا مدخل وغير قابلة للوصول**.

## ثانياً: مقارنة المسارات الأساسية في HarmonyOS

| المسار الأساسي | الوضع الحالي | نوع الفجوة |
|---------|------|---------|
| الدفع | الصفحة موجودة، API يعمل | واجهة فقط: لا مدخل في Home (غير قابل للوصول) |
| الإصلاح | صفحات القائمة والإرسال موجودة، API يعمل | واجهة فقط: لا مدخل في Home (غير قابل للوصول) |
| الإعلان | الصفحة موجودة، API يعمل | واجهة فقط: لا مدخل في Home (غير قابل للوصول) |
| الزوار | الصفحة مفقودة | يحتاج صفحة جديدة (API موجود: GET/POST/PUT/DELETE /visitor*) |
| المواقف | الصفحة مفقودة | يحتاج صفحة جديدة (API موجود: /parking/vehicles、/parking/spaces、/parking/records) |

لا توجد فجوات في الخادم: جميع واجهات service للمسارات الأساسية الخمسة جاهزة (fees/repairs/announcements مسارات دائمة؛ parking/visitors داخل بوابة إصدار standard). يحتوي ApiService.ets بالفعل على get/post/put/delete عامة، ويمكن للصفحات الجديدة إعادة استخدامها مباشرة.

## ثالثاً: الوضع الحالي لتطبيق Flutter للملاك (apps/flutter، 13 وحدة)

**قائمة الصفحات**: login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — جميعها مسجلة في المسارات (app.dart getPages)، والمسارات الأساسية الخمسة منفذة بالكامل.

**مشكلة تكييف الجوال**: فقط home_page / login_page تستخدمان LayoutBuilder/MediaQuery لنقاط الاستجابة؛ **10 صفحات بعرض مكتبي مكتوب يدوياً**، فيعرضها هاتف بعرض أقل من 400px حتماً لخطأ RenderFlex:

| الصفحة | القيم المكتوبة |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | بلا معالجة نقاط الاستجابة (متوقع مشكلة مماثلة، لم يُدقق سطراً بسطر) |

أيضاً: لا يوجد شريط تنقل سفلي (BottomNavigationBar)، المداخل عبر AppBar + شبكة؛ padding الصفحات 24 بأسلوب مكتبي. التدويل ثنائي اللغة متوفر.

## رابعاً: قائمة الفجوات (تصنيف + حجم العمل)

### يعتمد على الخادم (لا يوجد)

### واجهة فقط

| # | البند | حجم العمل |
|---|----|--------|
| 1 | إضافة شبكة مداخل وظيفية إلى HomePage في HarmonyOS (مقارنة بمداخل Flutter الـ12)، وربط الدفع/الإصلاح/الإعلان/الزوار/المواقف/المركز الشخصي | M |
| 2 | صفحة VisitorPage جديدة في HarmonyOS (قائمة + إضافة، إعادة استخدام VisitorController) | M |
| 3 | صفحة ParkingPage جديدة في HarmonyOS (مركبات/مواقف/سجلات، إعادة استخدام ParkingController) | M |
| 4 | إزالة العروض المكتوبة يدوياً في Flutter بوابة الملاك (600/800/480 ← تقييد ضمن maxWidth أو استخدام ConstrainedBox) | S |
| 5 | إضافة شريط تنقل سفلي + padding مضغوط في Flutter بوابة الملاك (إذا كان الجوال هدفاً للقبول) | M |

### يتطلب ربطاً مشتركاً

| # | البند | حجم العمل |
|---|----|--------|
| 6 | التحقق على جهاز HarmonyOS حقيقي/محاكي من السلسلة الكاملة للدفع←الدفع، وإرسال طلب الإصلاح، وتسجيل الزوار | S (مقيد بأجهزة الاختبار، PROJECT_PLAN أدرج هذا الخطر) |

## خامساً: ترتيب التنفيذ المقترح

1. الفجوة 1 (أعلى قيمة مقابل التكلفة: إعادة استخدام الصفحات الثلاث الموجودة، بدون أي صفحة جديدة)
2. الفجوة 4 (فيض Flutter عيب جوهري، الهاتف سيتعطل حتماً)
3. الفجوتان 2 و3 (صفحات جديدة)
4. الفجوة 5 (تحسين التجربة)
5. الفجوة 6 (تتطلب أجهزة، تُنفذ بشكل مستقل)

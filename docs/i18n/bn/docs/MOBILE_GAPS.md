# মোবাইল গ্যাপ পূরণের তালিকা

> তৈরি তারিখ: 2026-08-16 · উৎস: pmp-team ci-agent (P3-③ বর্তমান অবস্থা জরিপ, শুধুমাত্র পঠনযোগ্য)
> সংশ্লিষ্ট রোডম্যাপ: docs/PROJECT_PLAN.md P3 — "HarmonyOS ৭ পেজ থেকে কোর পাথে সম্প্রসারণ (ফি পরিশোধ/মেরামত/ঘোষণা/দর্শনার্থী/পার্কিং), Flutter মালিক পোর্টাল মোবাইল অ্যাডাপ্টেশন"

## ১. HarmonyOS মালিক পোর্টালের বর্তমান অবস্থা (apps/harmonyos, ৭ পেজ)

| পেজ | রুট (main_pages.json-এ নিবন্ধিত) | কল করা API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | লগইন (AuthService) |
| HomePage | pages/HomePage | GET /service/home (ড্যাশবোর্ড: বকেয়া/ওয়ার্ক অর্ডার/সম্পত্তির সংখ্যা + ঘোষণা তালিকা) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile, POST /service/profile/logout |

**নেভিগেশনের বর্তমান অবস্থা** (পুরো অ্যাপে মাত্র ৪টি জাম্প): Login→Home, Home→Login (লগআউট), Profile→Login, RepairList→RepairSubmit। HomePage-এ শুধু পরিসংখ্যান কার্ড + ঘোষণা তালিকা আছে, ফাংশন এন্ট্রি গ্রিড নেই; FeeBills/Announcement/Profile পেজ আছে কিন্তু **কোনো এন্ট্রি নেই, অ্যাক্সেসযোগ্য নয়**।

## ২. HarmonyOS কোর পাথ তুলনা

| কোর পাথ | বর্তমান অবস্থা | গ্যাপের ধরন |
|---------|------|---------|
| ফি পরিশোধ | পেজ আছে, API কাজ করে | খাঁটি ফ্রন্টএন্ড: Home-এ এন্ট্রি নেই (অ্যাক্সেসযোগ্য নয়) |
| মেরামত | তালিকা+জমা পেজ আছে, API কাজ করে | খাঁটি ফ্রন্টএন্ড: Home-এ এন্ট্রি নেই (অ্যাক্সেসযোগ্য নয়) |
| ঘোষণা | পেজ আছে, API কাজ করে | খাঁটি ফ্রন্টএন্ড: Home-এ এন্ট্রি নেই (অ্যাক্সেসযোগ্য নয়) |
| দর্শনার্থী | পেজ নেই | নতুন পেজ তৈরি করতে হবে (API আছে: GET/POST/PUT/DELETE /visitor*) |
| পার্কিং | পেজ নেই | নতুন পেজ তৈরি করতে হবে (API আছে: /parking/vehicles, /parking/spaces, /parking/records) |

ব্যাকএন্ডে কোনো গ্যাপ নেই: ৫টি কোর পাথের service API সব প্রস্তুত (fees/repairs/announcements স্থায়ী রুট; parking/visitors standard সংস্করণের গেটের মধ্যে)। ApiService.ets-এ সাধারণ get/post/put/delete আছে, নতুন পেজ সরাসরি পুনঃব্যবহার করতে পারে।

## ৩. Flutter মালিক পোর্টালের বর্তমান অবস্থা (apps/flutter, ১৩ মডিউল)

**পেজ তালিকা**: login, home, fee, repair, parking×3, visitor×2, activity, notification, vote, mall×3, chat, face, profile — সব রুট নিবন্ধিত (app.dart getPages), ৫টি কোর পাথ সব বাস্তবায়িত।

**মোবাইল অ্যাডাপ্টেশন সমস্যা**: শুধুমাত্র home_page / login_page LayoutBuilder/MediaQuery রেসপন্সিভ ব্রেকপয়েন্ট ব্যবহার করে; **১০টি পেজে ডেস্কটপ প্রস্থ হার্ডকোড করা**, মোবাইল প্রস্থে (<400px) RenderFlex ওভারফ্লো নিশ্চিত:

| পেজ | হার্ডকোড করা |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail, parking_records/vehicles, visitor_list, face_register | ব্রেকপয়েন্ট নেই (একই ধরনের সমস্যা প্রত্যাশিত, লাইন ধরে যাচাই করা হয়নি) |

অতিরিক্ত: নিচের নেভিগেশন বার (BottomNavigationBar) নেই, এন্ট্রি AppBar + গ্রিডে; পেজ padding ২৪ ডেস্কটপ-স্টাইল। i18n দ্বিভাষিকতা আছে।

## ৪. গ্যাপ তালিকা (শ্রেণিবিভাগ + কাজের পরিমাণ)

### ব্যাকএন্ড নির্ভরশীল (কোনোটিই নয়)

### খাঁটি ফ্রন্টএন্ড

| # | আইটেম | কাজের পরিমাণ |
|---|----|--------|
| 1 | HarmonyOS HomePage-এ ফাংশন এন্ট্রি গ্রিড যোগ করা (Flutter সংস্করণের ১২ এন্ট্রির সাথে তুলনা করে), ফি পরিশোধ/মেরামত/ঘোষণা/দর্শনার্থী/পার্কিং/ব্যক্তিগত কেন্দ্র সংযুক্ত করা | M |
| 2 | HarmonyOS-এ নতুন VisitorPage (তালিকা + নতুন, VisitorController পুনঃব্যবহার) | M |
| 3 | HarmonyOS-এ নতুন ParkingPage (যানবাহন/স্পট/রেকর্ড, ParkingController পুনঃব্যবহার) | M |
| 4 | Flutter মালিক পোর্টালে হার্ডকোড করা প্রস্থ দূর করা (600/800/480 → maxWidth-এর মধ্যে সীমাবদ্ধ বা ConstrainedBox পরিবর্তন) | S |
| 5 | Flutter মালিক পোর্টালে বটম নেভিগেশন বার + কমপ্যাক্ট padding যোগ (যদি মোবাইল টার্গেট হয়) | M |

### সমন্বয় প্রয়োজন

| # | আইটেম | কাজের পরিমাণ |
|---|----|--------|
| 6 | HarmonyOS রিয়েল ডিভাইস/এমুলেটরে ফি পরিশোধ→পেমেন্ট, মেরামত জমা, দর্শনার্থী নিবন্ধন সম্পূর্ণ চেইন যাচাই | S (টেস্ট ডিভাইস সীমাবদ্ধ, PROJECT_PLAN-এ এই ঝুঁকি উল্লেখ আছে) |

## ৫. বাস্তবায়নের ক্রম সুপারিশ

1. গ্যাপ ১ (সর্বোচ্চ খরচ-কার্যকারিতা: বিদ্যমান ৩টি পেজ পুনঃব্যবহার, শূন্য নতুন পেজ)
2. গ্যাপ ৪ (Flutter ওভারফ্লো কঠিন সমস্যা, মোবাইলে অবশ্যই ক্র্যাশ)
3. গ্যাপ ২, ৩ (নতুন পেজ)
4. গ্যাপ ৫ (অভিজ্ঞতা অপ্টিমাইজেশন)
5. গ্যাপ ৬ (ডিভাইস প্রয়োজন, আলাদাভাবে করা)

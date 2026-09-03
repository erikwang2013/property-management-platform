# मोबाइल प्लेटफ़ॉर्म अंतराल सूची

> जनरेशन दिनांक: 2026-08-16 · स्रोत: pmp-team ci-agent (P3-③ वर्तमान स्थिति सर्वेक्षण, केवल-पठन)
> संबंधित रोडमैप: docs/PROJECT_PLAN.md P3 — "HarmonyOS 7 पेज को मुख्य पथ तक विस्तारित करें (भुगतान/मरम्मत/घोषणा/अतिथि/पार्किंग), Flutter मालिक पोर्टल मोबाइल अनुकूलन"

## 1. HarmonyOS मालिक पोर्टल वर्तमान स्थिति (apps/harmonyos, 7 पेज)

| पेज | रूट (main_pages.json में पंजीकृत) | कॉल किया गया API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | लॉगिन (AuthService) |
| HomePage | pages/HomePage | GET /service/v1/home (डैशबोर्ड: बकाया/कार्य आदेश/संपत्ति संख्या + घोषणा सूची) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**नेविगेशन वर्तमान स्थिति** (पूरे ऐप में केवल 4 जंप): Login→Home、Home→Login (लॉगआउट)、Profile→Login、RepairList→RepairSubmit। HomePage में केवल स्टैटिस्टिक्स कार्ड + घोषणा सूची है, कोई फ़ंक्शन प्रवेश ग्रिड नहीं; FeeBills/Announcement/Profile पेज मौजूद हैं लेकिन **कोई प्रवेश नहीं, पहुंच योग्य नहीं**।

## 2. HarmonyOS मुख्य पथ तुलना

| मुख्य पथ | वर्तमान स्थिति | अंतराल प्रकार |
|---------|------|---------|
| भुगतान | पेज है, API काम करता है | केवल फ्रंटएंड: Home में कोई प्रवेश नहीं (पहुंच योग्य नहीं) |
| मरम्मत | सूची+सबमिट पेज है, API काम करता है | केवल फ्रंटएंड: Home में कोई प्रवेश नहीं (पहुंच योग्य नहीं) |
| घोषणा | पेज है, API काम करता है | केवल फ्रंटएंड: Home में कोई प्रवेश नहीं (पहुंच योग्य नहीं) |
| अतिथि | पेज अनुपलब्ध | नया पेज बनाना आवश्यक (API पहले से मौजूद: GET/POST/PUT/DELETE /visitor*) |
| पार्किंग | पेज अनुपलब्ध | नया पेज बनाना आवश्यक (API पहले से मौजूद: /parking/vehicles、/parking/spaces、/parking/records) |

बैकएंड में कोई अंतराल नहीं: 5 मुख्य पथों के service API सभी तैयार हैं (fees/repairs/announcements स्थायी रूट; parking/visitors standard संस्करण के गेट के भीतर)। ApiService.ets में पहले से सामान्य get/post/put/delete है, नए पेज सीधे पुनः उपयोग कर सकते हैं।

## 3. Flutter मालिक पोर्टल वर्तमान स्थिति (apps/flutter, 13 मॉड्यूल)

**पेज सूची**: login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — सभी रूट पंजीकृत (app.dart getPages), 5 मुख्य पथ सभी लागू।

**मोबाइल अनुकूलन समस्या**: केवल home_page / login_page LayoutBuilder/MediaQuery रिस्पॉन्सिव ब्रेकपॉइंट का उपयोग करते हैं; **10 पेजों में डेस्कटॉप चौड़ाई हार्डकोड है**, फोन चौड़ाई (<400px) पर RenderFlex ओवरफ्लो निश्चित है:

| पेज | हार्डकोड |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | कोई ब्रेकपॉइंट प्रोसेसिंग नहीं (समान समस्या अपेक्षित, पंक्ति-दर-पंक्ति सत्यापित नहीं) |

इसके अलावा: कोई बॉटम नेविगेशन बार (BottomNavigationBar) नहीं, प्रवेश AppBar + ग्रिड पर निर्भर; पेज padding 24 डेस्कटॉप शैली की ओर। i18n द्विभाषी पहले से मौजूद है।

## 4. अंतराल सूची (वर्गीकरण + कार्यभार)

### बैकएंड पर निर्भर (कोई नहीं)

### केवल फ्रंटएंड

| # | आइटम | कार्यभार |
|---|----|--------|
| 1 | HarmonyOS HomePage में फ़ंक्शन प्रवेश ग्रिड जोड़ें (Flutter संस्करण के 12 प्रवेश के अनुरूप), भुगतान/मरम्मत/घोषणा/अतिथि/पार्किंग/व्यक्तिगत केंद्र जोड़ें | M |
| 2 | HarmonyOS में VisitorPage जोड़ें (सूची + नया, VisitorController पुनः उपयोग) | M |
| 3 | HarmonyOS में ParkingPage जोड़ें (वाहन/पार्किंग स्थल/रिकॉर्ड, ParkingController पुनः उपयोग) | M |
| 4 | Flutter मालिक पोर्टल में हार्डकोड चौड़ाई हटाएं (600/800/480 → maxWidth के भीतर सीमित करें या ConstrainedBox बदलें) | S |
| 5 | Flutter मालिक पोर्टल में बॉटम नेविगेशन बार + कॉम्पैक्ट padding जोड़ें (यदि फोन संस्करण स्वीकृति लक्ष्य है) | M |

### संयुक्त परीक्षण आवश्यक

| # | आइटम | कार्यभार |
|---|----|--------|
| 6 | HarmonyOS वास्तविक डिवाइस/सिम्युलेटर पर भुगतान→पेमेंट, मरम्मत सबमिट, अतिथि पंजीकरण पूर्ण श्रृंखला सत्यापित करें | S (परीक्षण डिवाइस की बाधा के कारण, PROJECT_PLAN में यह जोखिम सूचीबद्ध है) |

## 5. कार्यान्वयन क्रम सुझाव

1. अंतराल 1 (सर्वोच्च मूल्य-प्रदर्शन: मौजूदा 3 पेज पुनः उपयोग, शून्य नए पेज)
2. अंतराल 4 (Flutter ओवरफ्लो गंभीर समस्या है, फोन पर अनिवार्य रूप से क्रैश)
3. अंतराल 2, 3 (नए पेज)
4. अंतराल 5 (अनुभव अनुकूलन)
5. अंतराल 6 (डिवाइस आवश्यक, स्वतंत्र रूप से आगे बढ़ें)

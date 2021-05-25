local mail = {}
mail[1] = {
    ["name"] = "مكافآت الحلبة اليومية",
    ["content"] = "أحسنت الحصول على ترتيب #rank# في #id# اللعبة خلال #time#. ستجد المكافآت في المرفق.",
    ["from"] = "بريد الحلبة",
}
mail[2] = {
    ["name"] = "مكافأة موسمية",
    ["content"] = "أنا مبعوث ملك المملكة،  أهنئك على الترتيب #rank# في #id# اللعبة. مهاراتك الممتازة وشجاعتك أهلتك للحصول على المكافآت التالية",
    ["from"] = "بريد الحلبة",
}
mail[3] = {
    ["name"] = "تعيين قائد",
    ["content"] = "# member1 # لم يعد زعيم النقابة. # member2 # هو زعيمنا الجديد",
    ["from"] = "بريد النقابة",
}
mail[4] = {
    ["name"] = "تعيين المسؤليين",
    ["content"] = "تم تعيينك #guildname# بشكل رسمي",
    ["from"] = "بريد النقابة",
}
mail[5] = {
    ["name"] = "إعادة اتصال",
    ["content"] = "لم تعد مسؤلا في #guildname#",
    ["from"] = "بريد النقابة",
}
mail[6] = {
    ["name"] = "طرد من النقابة",
    ["content"] = "تم طردك من #guildname#",
    ["from"] = "بريد النقابة",
}
mail[7] = {
    ["name"] = "رفض النقابة",
    ["content"] = "#guildname# تم حلّها. ليس لديك نقابة الآن",
    ["from"] = "بريد النقابة",
}
mail[8] = {
    ["name"] = "مكافأة قائد النقابة",
    ["content"] = "مكافأة الإنجازات الخاصة بك في معركة قائد النقابة، يرجى اتخاذ المكافآت في المرفق.",
    ["from"] = "بريد النقابة",
}
mail[9] = {
    ["name"] = "نقاط الخادم الجديد",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 رقائق، 2 تذكرة للحلبة. يرجى استلام المكافآت في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[10] = {
    ["name"] = "اقتراحات اللعبة",
    ["content"] = "#content#",
    ["from"] = "بريد اللعبة",
}
mail[11] = {
    ["name"] = "اقتراحات اللعبة",
    ["content"] = "#content#",
    ["from"] = "بريد اللعبة",
}
mail[12] = {
    ["name"] = "أنت الآن تستخدم البطاقة الشهرية",
    ["content"] = "أنت مستخدم البطاقة الشهرية الآن. سيقوم النظام بإرسال #gems# جوهرة في 00:00 صباحا (UTC /GMT 0) لك يوميا منذ #date#. يتم تقديم الجواهر في أول يوم للشراء.",
    ["from"] = "بطاقة شهرية",
}
mail[13] = {
    ["name"] = "يوم مكافأة البطاقة الشهرية",
    ["content"] = "أعزائي VIP #number# اللاعبين، يرجى استلام المكافآت التالية في الوقت المناسب. ستنتهي صلاحية بطاقتك الشهرية خلال #day# يوم.",
    ["from"] = "بطاقة شهرية",
}
mail[14] = {
    ["name"] = "انتهت مدة صلاحية البطاقة الشهرية",
    ["content"] = "انتهت صلاحية بطاقتك الشهرية. يرجى تجديدها في المتجر للحصول على 9750 جوهرة!",
    ["from"] = "بطاقة شهرية",
}
mail[15] = {
    ["name"] = "مكافأة ارتفاع المستوى",
    ["content"] = "أحسنت على الوصول إلى  #level#. يرجى استلام #gems# و #gold# عملة ذهبية في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[16] = {
    ["name"] = "حدث الاستدعاء المجنون",
    ["content"] = "تهانينا على الحصول على #ID# البطل في هذا الحدث. يرجى استلامها في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[17] = {
    ["name"] = "قم بالتحميل للحصول على جوائز",
    ["content"] = "لقد قمت بتنزيل التطبيق الموصى به. يرجى استلام #gems# جوهرة في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[18] = {
    ["name"] = "غارة معركة النقابة",
    ["content"] = " قد شاركت في معركة في غارة النقابة في #date#. يرجى أخذ المكافآت في المرفق",
    ["from"] = "بريد النقابة",
}
mail[19] = {
    ["name"] = "مكافأة التقييم",
    ["content"] = "شكرا لدعمك. يرجى أستلام المكافآت في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[20] = {
    ["name"] = "مكافأة الفيديو",
    ["content"] = "شكرا لدعمك. يرجى أستلام المكافآت في المرفق",
    ["from"] = "بريد الإعداد",
}
mail[21] = {
    ["name"] = "ملاحظة التسجيل في حرب النقابة",
    ["content"] = "تم تسجيل  النقابة الخاصة بك في حصن #stage#  . يرجى الذهاب إلى حرب النقابة والاستعداد",
    ["from"] = "حرب النقابة",
}
mail[22] = {
    ["name"] = "مكافأة حرب النقابة",
    ["content"] = "قد أخذت حصن #stage#  في الجولة #number# من حرب النقابة. يرجى أخذ المكافآت التالية:",
    ["from"] = "حرب النقابة",
}
mail[23] = {
    ["name"] = "مكافأة الجولة الثانية في حرب النقابة",
    ["content"] = "لمكافأة أدائك الشجاع في حرب النقابة، يرجى استلام المكافآت التالية",
    ["from"] = "حرب النقابة",
}
mail[24] = {
    ["name"] = "مكافأة بطل حرب النقابة",
    ["content"] = "أنت بطل حرب النقابة هذه. يرجى أخذ المكافآت التالية",
    ["from"] = "حرب النقابة",
}
mail[25] = {
    ["name"] = "مكافآت غارة النقابة",
    ["content"] = "تهانينا نصرك على قائد النقابة، لقدت حصلت على المكافآت التالية:",
    ["from"] = "بريد النقابة",
}
mail[26] = {
    ["name"] = "مكافأة نقطة الاستدعاء",
    ["content"] = "لقد حصلت على #number# نقطة في حدث نقاط الاستدعاء. يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[27] = {
    ["name"] = "مكافأة عيد الشكر",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على #gems# جوهرة، #chip# رقائق. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[28] = {
    ["name"] = "مكافأة رأس السنة",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 رقائق، 2 دمى عجيبة. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[29] = {
    ["name"] = "مكافأة الكازينو",
    ["content"] = "لقد حصلت على #number# نقطة في حدث مكافآت الكازينو. يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[30] = {
    ["name"] = "مكافأة الشتاء",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 استدعاء بطولي. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[31] = {
    ["name"] = "مكافأة الشتاء",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 دمى عجيبة. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[32] = {
    ["name"] = "مكافأة تحدي حافة الموت",
    ["content"] = "أصبح ترتيبك #number# في تحدي حافة الموت. يرجى أخذ المكافآت في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[33] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 100 جوهرة، 1 استدعاء بطولي. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[34] = {
    ["name"] = "مكافأة العيد",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 استدعاء بطولي. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[35] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 50 جوهرة، 2 دمى عجيبة. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[36] = {
    ["name"] = "مكافأة الاستدعاء الاحترافي",
    ["content"] = "أحسنت! لقد أكملت متطلبات الاستدعاء الأسطوري. يرجى أخذ المكافآت في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[37] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 100 جوهرة، 1 استدعاء بطولي. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[38] = {
    ["name"] = "مكافأة الحزمة المجنونة",
    ["content"] = "لقد حصلت على #number# نقطة في حدث الحزمة المجنونة. يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[39] = {
    ["name"] = "مكافآت القتال العنيف",
    ["content"] = "تهانينا على هزيمتك للقائد، تفضل باستلام المكافآت التالية:",
    ["from"] = "بريد الإعداد",
}
mail[40] = {
    ["name"] = "مكافآت ترتيب القتال العنيف",
    ["content"] = "تهانينا لترتيبك رقم # رتبة # في مساعدة القتال، يرجى المطالبة بالمكافآت الخاصة بك:",
    ["from"] = "بريد الإعداد",
}
mail[41] = {
    ["name"] = "بطاقة شهرية صغيرة",
    ["content"] = "أنت مستخدم بطاقة شهرية صغيرة الآن. سيقوم النظام بإرسال #gems# جوهرة في 00:00 صباحا (UTC / GMC 0) لك يوميا منذ #date#.سيتم تقديم الجواهر فور يوم الشراء.",
    ["from"] = "بطاقة شهرية مصغرة",
}
mail[42] = {
    ["name"] = "مكافأة البطاقة الشهرية الصغيرة",
    ["content"] = "عزيزي اللاعب، يرجى أخذ المكافآت التالية في الوقت المناسب. ستنتهي صلاحية البطاقة الشهرية الصغيرة في #day# يوم.",
    ["from"] = "بطاقة شهرية مصغرة",
}
mail[43] = {
    ["name"] = "انتهت مدة صلاحية البطاقة الشهرية الصغيرة",
    ["content"] = "انتهت صلاحية بطاقتك الشهرية. يرجى تجديدها في المتجر للحصول على 2500 الأحجار جوهرة!",
    ["from"] = "بطاقة شهرية مصغرة",
}
mail[44] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، سوف تحصل على مكافآت تسجيل الدخول اليومية بما في ذلك 5 رقائق.",
    ["from"] = "بريد الإعداد",
}
mail[45] = {
    ["name"] = "حدث الدمج",
    ["content"] = "تهانينا لاندماجك الناجح من مستوى 5 نجوم #ID# في وقت الحدث، يرجى المطالبة بالمكافآت الخاصة بك:",
    ["from"] = "بريد الإعداد",
}
mail[46] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، سوف تحصل على مكافآت تسجيل الدخول اليومية بما في ذلك أجزاء بطل ذو 4 نجوم x 30، رقائق x 3.",
    ["from"] = "بريد الإعداد",
}
mail[47] = {
    ["name"] = "مكافآت حدث المتنافسين",
    ["content"] = "تهانينا! قد استوفيت شروط حدث مهرجان المتنافسين. يمكنك الحصول على المكافآت الغنية الآن! للتفاصيل يرجى الاطلاع على المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[48] = {
    ["name"] = "هدايا أثرية",
    ["content"] = "قم بتسجيل الدخول اليومي في وقت الحدث للحصول على قطعة أثرية ذو 3 نجوم أرجوانية و 500 غبار سحري تجدهم مرسلين لك في بريد اللعبة.",
    ["from"] = "بريد الإعداد",
}
mail[49] = {
    ["name"] = "مكافأة عيد الشكر",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على عين النبي × 1، أجزاء بطل ذو 5 نجوم 10. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[50] = {
    ["name"] = "مكافآت جولة تأهيل حرب النقابة",
    ["content"] = "تهانينا للحصول على المرتبة #rank# في حرب النقابة في جولة التصفيات، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[51] = {
    ["name"] = "مكافآت نهائيات حرب النقابة",
    ["content"] = "تهانينا للحصول على المرتبة #rank# في حرب النقابة في جولة النهائيات، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[52] = {
    ["name"] = "مكافآت نهائيات حرب النقابة",
    ["content"] = "تهانينا للحصول على المرتبة الثانية في حرب النقابة في جولة النهائيات، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[53] = {
    ["name"] = "مكافآت نهائيات حرب النقابة",
    ["content"] = "تهانينا للفوز على البطل في نهائي حرب النقابة، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[54] = {
    ["name"] = "مكافآت حدث مهام الحانة ذو 4 نجوم",
    ["content"] = "تهانينا لاستكمال المهام ذو 4 نجوم في حدث مهام الحانة، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[55] = {
    ["name"] = "مكافآت حدث مهام الحانة ذو 5 نجوم",
    ["content"] = "تهانينا لاستكمال المهام ذو 5 نجوم في حدث مهام الحانة، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[56] = {
    ["name"] = "الانضمام إلى نقابة",
    ["content"] = "تهانينا، لقد انضممت إلى نقابة #guildname# ، تذكر أن تقوم بتسجيل الدخول كل يوم!",
    ["from"] = "بريد النقابة",
}
mail[57] = {
    ["name"] = "جائزة رأس السنة",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على استدعاء بطولي × 2، دمية الثلج × 50. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[58] = {
    ["name"] = "هدية العام الجديد",
    ["content"] = "During the event, login every day and you will GEMS x 200 , 5 Star Hero Shard x 15. Please get your rewards from the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[59] = {
    ["name"] = "محاولة البطل",
    ["content"] = "عزيزي اللاعب، قد فتحت محاولة بطل بالفعل، نقدم لكم مع تذاكر الحلبة × 5، اذهب الآن واستعد للمعركة!",
    ["from"] = "بريد الإعداد",
}
mail[60] = {
    ["name"] = "اقتراحات اللعبة",
    ["content"] = "#content1# #link_text# #link_url# #content2#",
    ["from"] = "بريد اللعبة",
}
mail[61] = {
    ["name"] = "هدية احتفال الربيع",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على عين النبي × 1، دمية الثلج × 50. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[62] = {
    ["name"] = "مكافآت حدث مهام الحانة ذو 6 نجوم",
    ["content"] = "تهانينا لاستكمال المهام 6 نجوم في حدث مهام الحانة، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[63] = {
    ["name"] = "مكافآت حدث مهام الحانة ذو 7 نجوم",
    ["content"] = "تهانينا لاستكمال المهام 7 نجوم في حدث مهام الحانة، وهنا هي المكافآت:",
    ["from"] = "بريد الإعداد",
}
mail[64] = {
    ["name"] = "هدية عيد الحب",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على القلب x10، جوهرةx100 أجزاء بطل ذو 5 نجوم x10. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[65] = {
    ["name"] = "حدث الدمج",
    ["content"] = "تهانينا لاندماجك ذو 6 نجوم الناجح #ID# في وقت الحدث، يرجى استلام المكافآت الخاصة بك:",
    ["from"] = "بريد الإعداد",
}
mail[66] = {
    ["name"] = "حلبة تشكيل الفريق المجاني",
    ["content"] = "تهانينا! لقد انضممت إلى الفريق بنجاح.",
    ["from"] = "بريد الحلبة",
}
mail[67] = {
    ["name"] = "قائد النقابة",
    ["content"] = "لا يمكنك الحصول على المكافآت مرة أخرى كلما قتلت القائد لعدة مرات.",
    ["from"] = "بريد النقابة",
}
mail[68] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 , Gems x 100. Please get your rewards from the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[69] = {
    ["name"] = "مكافأة نقطة الاستدعاء",
    ["content"] = "لقد حصلت على #number# نقطة في حدث نقاط الاستدعاء. يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[70] = {
    ["name"] = "بركة السماء",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على عين النبي×1، تمثال الذهب × 50. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[71] = {
    ["name"] = "بريد النقابة",
    ["content"] = "#content#",
    ["from"] = "بريد النقابة",
}
mail[72] = {
    ["name"] = "اقتراحات اللعبة",
    ["content"] = "عزيزي اللاعب، نحن نأسف لذلك بسبب مشكلة في الشبكة، لم تتلقى العناصر التي تم شراؤها مع order_id# through #platform#  #price#، ونحن سوف نعيد إرسال العناصر لك عن طريق بريد اللعبة الخاص بك، يرجى مراجعة تفاصيل المرفق",
    ["from"] = "بريد اللعبة",
}
mail[73] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على جوهرة x 100، استدعاء بطولي × 2. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[74] = {
    ["name"] = "مكافآت قتل القائد",
    ["content"] = "تهانينا! لقد قتلت القائد، يمكنك استلام المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[75] = {
    ["name"] = "مكافآت قتل القائد",
    ["content"] = "تهانينا! لقد قتلت قائد النقابة، يمكنك استلام المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[76] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على جوهرة x 200، رقاقات ×5. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[77] = {
    ["name"] = "الحلبة المكسورة",
    ["content"] = "Dear player, the Broken Space has already opened, we present you with Challenge Badge x 4 , go and prepare for battle!",
    ["from"] = "بريد الإعداد",
}
mail[78] = {
    ["name"] = "الحلبة المكسورة",
    ["content"] = "Dear player, the Broken Space has already opened, we present you with Challenge Badge x 5 , go and prepare for battle!",
    ["from"] = "بريد الإعداد",
}
mail[79] = {
    ["name"] = "مكافآت قتل قائد ضربة اللهب",
    ["content"] = "تهانينا! لقد قتلت قائد ضربة الجحيم في الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[80] = {
    ["name"] = "مكافآت قتل قائد ضوء الظلام",
    ["content"] = "تهانينا! لقد قتلت قائد ضوء الظلام في الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[81] = {
    ["name"] = "مكافآت قتل الشبح الآدمي",
    ["content"] = "تهانينا! لقد حصلت على ترتيب #rank# من قتلك الشبح الآدمي  قائد الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[82] = {
    ["name"] = "مكافأة الحلبة المكسورة",
    ["content"] = "تهانينا! لقد حصلت على ترتيب #rank# في الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[83] = {
    ["name"] = "مكافآت القتل بضوء الظلام",
    ["content"] = "تهانينا! لقد حصلت على ترتيب #rank# من قتلك قائد ضوء الظلام الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[84] = {
    ["name"] = "مكافآت قتل الشبح الآدمي",
    ["content"] = "تهانينا! لقد قتلت الشبح الآدمي  قائد الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[85] = {
    ["name"] = "مكافآت القتل بضربة اللهب",
    ["content"] = "تهانينا! لقد قتلت قائد ضربة الجحيم في الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[86] = {
    ["name"] = "مكافآت القتل بضوء الظلام",
    ["content"] = "تهانينا! لقد قتلت قائد ضوء الظلام في الحلبة المكسورة، يمكنك الحصول على المكافآت أدناه",
    ["from"] = "بريد الإعداد",
}
mail[87] = {
    ["name"] = "الذكرى السنوية الأولى",
    ["content"] = "During Event time, daily login will reward you Lucky Fishbones and gems with equal current level quantity. Rewards are in the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[88] = {
    ["name"] = "Novice Package",
    ["content"] = "Congratulations on the successful use of the redeem code #key# for the following rewards. Details please see the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[89] = {
    ["name"] = "Privilege Package",
    ["content"] = "Congratulations on the successful use of the redeem code #key# for the following rewards. Details please see the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[91] = {
    ["name"] = "FB Like event reward",
    ["content"] = "Greetings hero, thanks to your help, the Vicious Das Moge has been defeated, you saved our FB fan page! Please collect the loot which is 300 gems. ",
    ["from"] = "بريد الإعداد",
}
mail[92] = {
    ["name"] = "Sina Weibo Following Reward",
    ["content"] = "Heroes! Thanks for your following to our Sina Weibo webpage. Now our Sina Weibo fans have exceeded 15,000 people. Please claim the rewards of 400 gems.",
    ["from"] = "بريد الإعداد",
}
mail[93] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على 3 رقائق، 1 رقاقة خارقة. يرجى الحصول على المكافآت الخاصة بك في المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[94] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على أجزاء بطل ذو 5 نجوم x 10. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[95] = {
    ["name"] = "مكافأة مجد اليقظة",
    ["content"] = "تهانينا على الإنجاز الخاص بك في حدث مجد اليقظة، يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[96] = {
    ["name"] = "مكافأة المعجزة البطولية",
    ["content"] = "تهانينا على الإنجاز الخاص بك في حدث الإعجاز البطولي، يرجى الحصول على المكافآت التالية",
    ["from"] = "بريد الإعداد",
}
mail[97] = {
    ["name"] = "تحدي معجبين صفحة الفيسبوك",
    ["content"] = "Thanks to the efforts of our heroes, now vicious Malassa has been defeated, please claim your 400 gems as reward!",
    ["from"] = "بريد الإعداد",
}
mail[98] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "During the event, login every day and you will get Heroic Summon Scroll x 5, 5 Star Hero Shard x 15. Please get your rewards from the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[99] = {
    ["name"] = "إعادة تعيين الوحش",
    ["content"] = "قد تم إعادة تعيين كل الوحوش، وقد تم إرسال جميع المواد المستهلكة بما في ذلك الذهب إلى صندوق البريد الخاص بك، يرجى استلامهم من المرفق التالي.",
    ["from"] = "بريد الإعداد",
}
mail[100] = {
    ["name"] = "نقل قيادة الفريق",
    ["content"] = "قد تم نقل قيادة تشكيل الفريق في الحلبة إليك، يمكنك أداء واجبات قائد الفريق الخاص بك الآن.",
    ["from"] = "بريد الإعداد",
}
mail[101] = {
    ["name"] = "بريد تعويض طاحونة النقابة",
    ["content"] = "أعزائي اللاعبين، وضعنا تعديل جديد على طاحونة النقابة، سيتم إلغاء النظام الأصلي، يرجى قبول التعويض التالي.",
    ["from"] = "بريد الإعداد",
}
mail[102] = {
    ["name"] = "بريد تعويض",
    ["content"] = "Dear players, we feel very sorry for the loading problem on our Servers which is caused by some technical failure. Now we have fixed the issue and we would like to send you all Prophet Orb x 1 and 500 free gems for apologizing the frustrations, thank you for all your support on helping us fix this problem.",
    ["from"] = "بريد الإعداد",
}
mail[103] = {
    ["name"] = "Aspen Dungeon opens",
    ["content"] = "Dear players, Brand new Aspen Dungeon is about to open, please accept these materials, enjoy participating!",
    ["from"] = "بريد الإعداد",
}
mail[104] = {
    ["name"] = "Halloween event rewards",
    ["content"] = "Dear player, the following is your reward for redeeming in Halloween event.",
    ["from"] = "بريد الإعداد",
}
mail[105] = {
    ["name"] = "مكافآت قتل القائد",
    ["content"] = "Celestial island Boss has been slain by you, congratulations you get the following reward.",
    ["from"] = "بريد الإعداد",
}
mail[106] = {
    ["name"] = "بريد تعويض",
    ["content"] = "Dear players, we are sorry that the items you purchased didn’t arrive to your account in time due to network issue. We now resent them to your account by in-game email.",
    ["from"] = "بريد الإعداد",
}
mail[107] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "During the event, login every day and you will get Black treasure chest x 5. Please get your rewards from the attachment.",
    ["from"] = "بريد الإعداد",
}
mail[108] = {
    ["name"] = "Premium Black Gold Card reward",
    ["content"] = "You are #level# level VIP #number# user, get the following rewards today, and your Premium Black Gold Card expires in #day# day(s).",
    ["from"] = "بريد الإعداد",
}
mail[109] = {
    ["name"] = "بريد تعويض",
    ["content"] = "Dear player, we have adjusted the refreshing mechanics in Celestial Island, please claim the following compensation in attachment.",
    ["from"] = "بريد الإعداد",
}
mail[110] = {
    ["name"] = "プレーヤーの皆様",
    ["content"] = "こんにちは。Twitter公式アカウントを準備完了いたしました。ゲームの最新情報や、最新イベント内容は今発信中！Twitterで＠IdleHeroesJP公式アカウントをフォロワーしてお願いいたします。URL：https://twitter.com/IdleHeroesJPどうもありがとうございます。これからも、どうぞよろしくお願いいたします。",
    ["from"] = "システムメール",
}
mail[111] = {
    ["name"] = "Christmas gift",
    ["content"] = "During the event, login to get daily reward: gem and tiny snowman, quantity equals to your current level.",
    ["from"] = "بريد الإعداد",
}
mail[112] = {
    ["name"] = "GM우편",
    ["content"] = "아이들 히어로즈 카페에 가입해주셔서 진심으로 감사드립니다!",
    ["from"] = "시스템 우편",
}
mail[113] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "خلال هذا الحدث، قم بتسجيل الدخول كل يوم، وسوف تحصل على الاستدعاء البطولي ×2. يرجى الحصول على المكافآت الخاصة بك من المرفق.",
    ["from"] = "بريد الإعداد",
}
mail[114] = {
    ["name"] = "FB like challenge reward",
    ["content"] = "Congratulations, the Vicious Kroos has been defeated, now you can claim the loot, 450 gems for everyone!",
    ["from"] = "بريد الإعداد",
}
mail[115] = {
    ["name"] = "Like reward",
    ["content"] = "Thanks for your 'like' to our facebook like challenge post, here is your reward. Stay tuned with us on facebook or twitter, there will be more awesome events which grant generous reward, thanks!",
    ["from"] = "بريد الإعداد",
}
mail[116] = {
    ["name"] = "GM來信",
    ["content"] = "親愛的兵粉，邀請您關注我們的官方微信公眾號與微博（搜索：放置奇兵或者點擊以下官網連結掃描二維碼），我們會不定時的舉行各種福利活動以及爆料放置新旅程春節系列（重磅消息），趕緊來關注吧！|||http://ih.dhgames.cn|||http://ih.dhgames.cn|||",
    ["from"] = "系統郵件",
}
mail[117] = {
    ["name"] = "고객님들께",
    ["content"] = "안녕하세요, 여러분.  최신 게임 정보와 이벤트 활동 소식 등 우리 게임 Twitter를 통해서 전달 드리겠습니다.  아래 링크를 클릭해서 팔로우하세요~여러분의 응원 많이 부탁드려요. 감사합니다.|||https://twitter.com/IdleheroesKr|||https://twitter.com/IdleheroesKr|||",
    ["from"] = "시스템 우편",
}
mail[118] = {
    ["name"] = "بريد تعويض",
    ["content"] = "Dear players, we adjusted the content of the packs you purchased recently. Sorry for the inconvenience, please take the following compensation, items are attached.",
    ["from"] = "بريد الإعداد",
}
mail[119] = {
    ["name"] = "مكافأة يومية",
    ["content"] = "During Spring Festival Event, daily login will award you Magic Lantern x8, Sweetheart Chocolate x 6, rewards see attachment.",
    ["from"] = "بريد الإعداد",
}
mail[120] = {
    ["name"] = "New year Fortune Card",
    ["content"] = "You are #level# level VIP #number# user, get the following rewards today, and your New year Fortune Card expires in #day# day(s).",
    ["from"] = "بريد الإعداد",
}
mail[121] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 , Heroic Summon Scroll x 1 , Challenge Badge x 8. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[122] = {
    ["name"] = "华为论坛专属活动",
    ["content"] = "亲爱的兵粉，华为《放置奇兵》论坛现在正在举行专区特享故事编纂活动，最高能得到2018钻石和万能英雄碎片奖励，赶紧动动手指来参与吧！活动传送门：|||http://cn.club.vmall.com/thread-15343426-1-1.html|||http://cn.club.vmall.com/thread-15343426-1-1.html|||",
    ["from"] = "系统邮件",
}
mail[123] = {
    ["name"] = "مكافآت قتل القائد",
    ["content"] = "Congratulations! Flame Altar Boss was defeated,please claim your rewards:",
    ["from"] = "بريد الإعداد",
}
mail[124] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 , Ancient Statue x 50 . Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[125] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Arena Ticket x 2 , Gems x 100. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[126] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Super chip x 1 , Challenge Badge x 4 . Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[127] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Gems x 200. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[128] = {
    ["name"] = "Server merging rewards",
    ["content"] = "Dear Player: Server merging has been successfully completed. Thank you for your support. Please claim the rewards: Gem*2000, Universal skin shards*10.",
    ["from"] = "System Email",
}
mail[129] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 ,Challenge Badge x 4. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[130] = {
    ["name"] = "GM Feedback",
    ["content"] = "Dear players,we will merge our servers on #content# at 10:00 am. It will last about 2 to 4 hours, during the time period, players are unable to login our game. To avoid unnecessary loss, please prepare in advance for offline. After the merging is completed, we will send you Gems*2000, Universe Skin Shards*10. Sorry for the inconvenience it may cause you and thanks for your support to our game!",
    ["from"] = "GM Email",
}
mail[131] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 , Super chip x 1. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[132] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Super chip x 1 . Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[133] = {
    ["name"] = "2nd Anniversary Celebration",
    ["content"] = "Daily log-in Bonus during the event time: Lucky Commemorative Coins of current player levelx1, Gems of current player levelx1. Rewards are in the attachment.",
    ["from"] = "System Email",
}
mail[134] = {
    ["name"] = "Rewards of Anniversary Celebration Card",
    ["content"] = "You are a #level# VIP #number# user, today you can get the following rewards and your Anniversary Celebration Card will expire after #day# days.",
    ["from"] = "System Email",
}
mail[135] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 ,Lucky Commemorative Coin x 100. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[136] = {
    ["name"] = "الحلبة المكسورة",
    ["content"] = "Dear player, the Broken Space has already opened, we present you with Challenge Badge x 5 , go and prepare for battle!",
    ["from"] = "بريد الإعداد",
}
mail[137] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Heroic Summon Scroll x 2, Super chip x 1. Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[138] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Prophet Orb x 1 . Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
mail[139] = {
    ["name"] = "Daily Reward",
    ["content"] = "During the event, login every day and you will get Super chip x 1, Gems x 50 . Please get your rewards from the attachment.",
    ["from"] = "System Email",
}
return mail
local help = {}
help[1] = {
    ["title"] = "Binaların Fonksiyonu",
    ["describe"] = {
        {
            ["title"] = "Savaş",
            ["content"] = "Kahraman birliği savaşa gönderilir. Otomatik savaş işlemi başlatılır ve savaş tamamlanır. Savaş sırasında EXP, Altın, Ekipman v.b. ödüller kazanabilirsiniz. Etkinlik tarihlerinde düzensizlik olması halinde çift kat düşme süresi devreye girecektir."
        },
        {
            ["title"] = "Cesur Denemesi",
            ["content"] = "Aralıksız ve amansız savaşlarda, farklı sunuculardaki oyunculara meydan okuyabilirsiniz. Kahramanların HP değerleri bu deneme sırasında iyileşmez. Bu yüzden oldukça stratejik davranmanız gerekmektedir!"
        },
        {
            ["title"] = "Hayal Kulesi",
            ["content"] = "Hayal Kulesi her katında muhafızlar yer almaktadır. Onlara karşı zafer kazanırsanız büyük miktarda Kahraman Geliştirme Taşı ve güçlü ekipmanlardan kazanırsınız. Belirli bir kata ulaştıktan sonra 5 yıldızlı kahraman kazanabilirsiniz. Daha fazla kat sayısı daha fazla savaş demektir."
        },
        {
            ["title"] = "Arena",
            ["content"] = "Arena içerisindeki diğer oyunculara karşı meydan okuyun! Zafer kazanın, puanları toplayın. Büyük miktarda ücretsiz Elmas kazanıldı! Her Cuma, Cumartesi, Pazar (Sunucu Süresi) Şampiyon Denemesi açılır. Farklı sunuculardan gelen oyunculara karşı savaşın!"
        },
        {
            ["title"] = "Diziliş çağır",
            ["content"] = "Yeni kahramanlar çekmek en hızlı yoldur. Daha fazla Kalp ya da Çağırma Kitabı toplayarak ücretsiz kahraman çağırma işlemi yapabilirsiniz. Enerji çağırma dolduktan sonra herhangi 1 adet 5 yıldızlı kahraman kazanabilirsiniz."
        },
        {
            ["title"] = "Diziliş oluştur",
            ["content"] = "Kahraman yıldızı geliştirmek için zorunludur. Savaş dizilişi sırasında kahraman yıldız seviyesi geliştirilebilir. En fazla 6 yıldızdır. Gereken tüm malzemeleri toplayan kahramanlar savaş dizilişi sırasında kahraman yıldız seviyelerini geliştirebilirler. Yıldız geliştirdikten sonra malzeme tüketimi yapan kahraman karşılık gelen değerde Kahraman ve Kahraman Gelişim Taşı alacaklardır. Donatılan tüm diğer ekipmanlar çantaya geri döner. Mevcut kahraman ne kadar fazla ise, kahraman yıldız geliştirme fırsatı o kadar fazla olur!"
        },
        {
            ["title"] = "Sunak",
            ["content"] = "Kullanılmayan kahramanlarınız varsa, Sunak bölgesine giderek onları dağıtabilirsiniz. Kahraman dağıtarak belirli miktarda Elit Ruh, Kahraman Gelişim Taşı, Sihirli Toz, Ruh Taşı v.b. malzemeler çekilebilir. Dağıtılan kahramanın Ekipman, Kristal ve Gizemli Silahları çantaya geri gönderilir. Dağıtılan kahraman tarafından kazanılan Ruh Taşı Sunak Marketi üzerinden kahraman ile takas edilebilir! Ruh Taşı olduğu zaman etkinlik üzerinden satışı yapılan hediye paketleri kazanılabilir!"
        },
        {
            ["title"] = "Demirci",
            ["content"] = "Demirci üzerinden düşük seviyeli ekipman birleştirerek yüksek seviyeli ekipman elde edilebilir. Ekipman seti donatıldığında ekipmanın özellikleri aktif olur! Dikkat: Donatılmış olan ekipman tekrar Demirci dükkanına giremez."
        },
        {
            ["title"] = "Dilek Havuzu",
            ["content"] = "Dilek Havuzu üzerinde Dilek Parası tüketerek Kahraman Parçası, Ekipman, Gizemli Silah, Altın, Elit Ruh v.b. eşyalar kazanılabilir. İyi şanslar!"
        },
        {
            ["title"] = "Market",
            ["content"] = "Market belirli sürelerde yenilenmektedir (Elle yenileme de yapabilirsiniz) ve Elit Ruh, Elit Ruh Gelişim Taşı, Kahraman Parçası, Ekipman, Çağırma Kitabı, Arena Bileti, Çip v.b. eşyalar kazanılır."
        },
        {
            ["title"] = "Efendi Ağacı",
            ["content"] = "Efendi Ağacı üzerinde belirli kamplar çağrılabilir! Efendi Safir kullanarak belirli kampların çağırma kapısında çağırma işlemi yapılabilir. 4 yıldızlı Kamp, 5 yıldızlı Kahraman, 4 ve 5 yıldızlı Evrensel Parça kazanma olasılığı bulunmaktadır. (Efendi Safiri, Meyhane Görevi üzerinden kazanılabilir, ayrıca Etkinlik Takası yaparak da elde edilebilir. Düzensiz süreli etkinlikler sırasında Efendi Safiri satılmaktadır) Her çağırma işlemi sonrası ekstra Efendi Bereketi kazanılır. Belirli miktarda Efendi Bereketi tüketerek bir kampın kahramanlarını aynı kampın kahramanları olarak ayarlayabilirsiniz. Dikkat: Karanlık Kamp'a ait olmayan sadece 4 ve 5 yıldızlı kahramanlar yeniden ayarlanabilir."
        },
        {
            ["title"] = "Meyhane",
            ["content"] = "Meyhane üzerinde her 24 saatte bir farklı yıldız seviyelerinde kahraman görevi yenilenir. Kahraman görevini tamamlayarak zengin ödüllerin sahibi olabilirsiniz! Elmas harcayarak görevin yıldız seviyesi değiştirilebilir. Ayrıca görev daha hızlı tamamlanır. Meyhane Görev Kitabı kullanarak kahraman görevi artırılabilir (Yenileme sonrası kullanılmayan kitaplar yeniden ayarlanabilir). Meyhane Görevi Kitabı otomatik savaş sırasında kazanma olasılığı vardır."
        }
    },
}
help[2] = {
    ["title"] = "Bölüm Açıklaması",
    ["describe"] = {
        {
            ["title"] = "Genel Görünüm",
            ["content"] = "Savaş haritaları Normal, Kabus, Cehennem, Ölüm şeklinde 4 zorluk derecesine ayrılmaktadır. Her zorluk derecesinde bir çok bölüm yer almaktadır. Sırasıyla 3 adet zorluk derecesinin açılması gerekmektedir."
        },
        {
            ["title"] = "Bölüm kilidini aç",
            ["content"] = "Yeni bölüme gelip yeterli olarak keşif süresi için beklendiğinde savaş tetiklenir. Savaşı tamamlayarak savaş gücü ve seviyeniz bir sonraki bölüme girmek için yeterli seviyeye ulaştığında, sonraki bölüme ilerlemek için tıklanabilir."
        },
        {
            ["title"] = "Bölge & Harita Dağıtma",
            ["content"] = "Bir bölgedeki tüm bölümleri geçtikten sonra, bir sonraki bölgenin kilidi açılır. Herhangi bir zorluk modunda tüm bölümleri aştıktan sonra bir sonraki zorluk modu kilidi açılır."
        },
        {
            ["title"] = "Savaş Olayı",
            ["content"] = "Yeni bir bölüme girerek bu bölüme ait olan savaş tetiklenir. Bölümdeki savaş geçildikten sonra zengin ödüller kazanılır."
        },
        {
            ["title"] = "Birlik",
            ["content"] = "Birlik içerisinde küçük bir kahraman takımı ayarlanabilir. Ayarlanabilen birlik kişi sayısı seviyenize göre artar. Kahraman savaş gücü ne kadar yüksek olursa, savaşa giden kahraman sayısı ve birlik savaş gücü o kadar fazla olur. (Savaşa giden kahramanın savaş gücü sadece kilidi açık olan bölüm ile ilgilidir. Düşme durumu ile ilgisi yoktur)"
        },
        {
            ["title"] = "Otomatik",
            ["content"] = "Otomatik savaştan elde edilen kazançlar bazı sürelerde artış gösterir. En uzun 8 saat boyunca otomatik savaş yapabilirsiniz. 8 saatin sonunda yapılan otomatik savaştan kazanç elde edilmez. Bu yüzden 8 saat içerisinde gelip otomatik savaştan elde edilen kazançları çekmeyi unutmayınız!"
        },
        {
            ["title"] = "Üretim & Çekme",
            ["content"] = "Bölümlerde belirli miktarda EXP, Altın ve Elit Ruh elde edilir. Otomatik savaştan 3 tür kazanç çekilebilir. Bölümün zorluk derecesi ne kadar yüksek olursa bu kazançların miktarı o kadar fazla olur. VIP seviyesine karşılık gelecek şekilde düşen bu 3 kaynağın miktarı artar."
        },
        {
            ["title"] = "Düşen & Ganimet",
            ["content"] = "Eşya düşme bilgisinden mevcut bölümden düşebilecek olan eşyalara bakabilirsiniz. İlerleyip herhangi bir bölümde otomatik savaş başlattığınız zaman, bu bölümden düşen eşyalar kazanılacaktır. Kazanılmış olan düşen eşyalara savaş ganimetlerinden bakılabilir."
        }
    },
}
help[3] = {
    ["title"] = "Savaş",
    ["describe"] = {
        {
            ["title"] = "Savaş Konumu",
            ["content"] = "Normalde ön hatta duran kahramanların saldırıya uğraması arka sırada duranlara göre çok daha kolaydır. Kahramanların mesleklerine göre savaş pozisyonlarını ayarlamanız gerekmektedir. Bu şekilde savaş alanında hayatta kalma süreniz çok daha uzun olacaktır."
        },
        {
            ["title"] = "Kamp Kontrolü",
            ["content"] = "Kahramanlar arasında kamp kontrol bağlantısı bulunmaktadır. Savaş öncesinde düşmanın savaş dizilişine göre kahramanların ayarlanması savaş esnasında size avantaj sağlayacaktır."
        },
        {
            ["title"] = "Kamp Işık Halkası",
            ["content"] = "6 adet aynı kamptan olan kahraman ya da 6 adet tamamen farklı kamplardan olan kahramanların tümü güçlü bir ışık halkası etkisini aktif edecektir."
        },
        {
            ["title"] = "Savaş Kazanan/Kaybedenin Belirlenmesi",
            ["content"] = "Savaş turu sayısının 15 üzerinde olması savunan tarafın başarısızlığını belirleyecektir. Eleme turunda tüm düşmanı öldüren kahraman savaşın galibi olur. Eğer size ait olan kahramanların tümü düşman tarafından öldürülürse savaş kaybedilir."
        },
        {
            ["title"] = "Saldırı",
            ["content"] = "Kahraman saldırısı ne kadar fazla olursa, düşmana verilen zarar o kadar fazla olur."
        },
        {
            ["title"] = "HP",
            ["content"] = "Kahraman HP değeri ne kadar fazla ise, savaş sırasında hayatta kalma süresi o kadar uzun olur."
        },
        {
            ["title"] = "Zırh",
            ["content"] = "Kahraman koruma kalkanı ne kadar yüksek olursa, düşmanın kahramana verdiği zarar o kadar az olur."
        },
        {
            ["title"] = "Hız",
            ["content"] = "Hız her turdaki kahramanın çıkış sırasını belirlemektedir. Kahraman ne kadar hızlı olursa çıkış yüksek olduğundan dolayı ön sırada yer alır."
        },
        {
            ["title"] = "Beceri Zarar Oranı Arttırma",
            ["content"] = "Beceri zarar oranının artması becerinin verdiği zararı ekstra artıracaktır. Beceri zarar oranı ne kadar yüksek olursa, verdiği zarar o kadar fazla olur."
        },
        {
            ["title"] = "İsabet",
            ["content"] = "İsabet, düşmana yapılan saldırının isabet oranını ifade etmektedir. İsabet ne kadar yüksek olursa, isabetin başarı oranı o kadar yüksek olur."
        },
        {
            ["title"] = "Kaçış",
            ["content"] = "Kaçış, kahramanın saldırıdan isabet alma oranını etkiler. Kaçış ne kadar yüksek olursa düşman tarafından yapılan saldırının isabet oranı düşer."
        },
        {
            ["title"] = "Kritik Saldırı",
            ["content"] = "Kritik Saldırı tetiklenme oranıdır. Kahraman kritik saldırısı ne kadar yüksek olursa, kritik saldırı tetiklenme olasılığı o kadar büyük olur."
        },
        {
            ["title"] = "Kritik Vuruş Zararı",
            ["content"] = "Kritik saldırı tetiklendiği zaman zarar oluşur, kahraman kritik saldırısından kaynaklanan zarar ne kadar yüksek olursa kritik saldırı başarıyla tetiklendikten sonra oluşan zarar o kadar fazla olur."
        },
        {
            ["title"] = "Kalkan Kırma",
            ["content"] = "Saldırılan hedefin kalkan değerine karşı koyulur. Kahraman kalkan kırma değeri ne kadar yükse olursa, düşman kalkanına o kadar çok karşı koyulabilir."
        },
        {
            ["title"] = "Serbest Kontrol Oranı",
            ["content"] = "Düşman tarafından kontrol edilemez. Kahramanın serbest kontrolü ne kadar yüksek olursa, düşman tarafından kontrol edilme oranı o kadar düşer."
        },
        {
            ["title"] = "Zarar Azalma Oranı",
            ["content"] = "Verilen zarar oranı düşer. Kahramanın zarar düşme oranı ne kadar yüksek ise, düşman tarafından verilen zarar o kadar azalır."
        }
    },
}
help[4] = {
    ["title"] = "Kahraman Çekme Yöntemleri",
    ["describe"] = {
        {
            ["title"] = "Düşen Eşyalar",
            ["content"] = "Otomatik savaş sırasında, savaş geçilir, her gün etkinlik ek sahnesine katılım yapılır——Kahramanın savaşması ve Hayal Kulesi'ne saldırması ile kahraman parçaları düşer."
        },
        {
            ["title"] = "Market Satın Alma",
            ["content"] = "Market, Şans Marketi, Ruh Taşı Marketi, Cesur Deneme Marketi, Birlik Marketi, Şampiyon Deneme Marketi birimlerinde kahraman ve kahraman parçaları satışı yapılmaktadır."
        },
        {
            ["title"] = "Diziliş çağır",
            ["content"] = "Çağırma işlemi sırasında Kalp, Çağırma Kitabı, Elmas v.b. eşyaları kullanarak çağırma işlemi yapabilir ve hızlı bir şekilde yeni kahramanlardan çekebilirsiniz."
        },
        {
            ["title"] = "Efendi Ağacı",
            ["content"] = "Efendi Ağacı bölgesinde Efendi Safiri tüketip kahraman parçası elde edebilirsiniz!"
        },
        {
            ["title"] = "Dilek Havuzu",
            ["content"] = "Dilek Havuzu bölgesinde Dilek Parası harcayıp yapılan Dilek ile kahraman parçası kazanma olasılığı vardır."
        },
        {
            ["title"] = "Meyhane Görevi",
            ["content"] = "Meyhane üzerinde kahraman parçası ödülü için kahraman görevi görünme olasılığı vardır. Kahraman görevini tamamladıktan sonra belirli miktarda kahraman parçası kazanılır."
        },
        {
            ["title"] = "Arkadaş Arama",
            ["content"] = "Arkadaş araması yaparak belirli olasılıkla belirli sayıda kahraman parçası kazanma şansı vardır."
        }
    },
}
help[5] = {
    ["title"] = "Kahramanın Güçlenmesini Sağlayan Yöntemler",
    ["describe"] = {
        {
            ["title"] = "Kahraman Seviye Geliştirme",
            ["content"] = "Elit Ruh tüketerek kahramanın seviyesi geliştirilir."
        },
        {
            ["title"] = "Kahraman Geliştirme",
            ["content"] = "Kahraman seviyesi üst limite ulaştığı zaman, Kahraman Gelişim Taşı tüketerek kahramanın kalitesi artırılabilir."
        },
        {
            ["title"] = "Kahraman Yıldız Geliştirme",
            ["content"] = "Kahraman seviyesi ve kalitesi dolduktan sonra, kurulan dizilişten yıldız seviyesi geliştirilebilir. Yıldız seviyesi yükseldikten sonra kahraman özellikleri ve seviyesi artar. Ekipman ve kaliteler korunur."
        },
        {
            ["title"] = "Kahraman Uyanışı",
            ["content"] = "Malzeme tüketerek 6 yıldız üzeri kahraman kullanılıp uyanış gerçekleştirilir. Uyanış işlemi kahramanın yıldız seviyesini, özelliklerini artırır ve kahramanın pasif becerisi güçlenir. Tüketilen kahraman için belirli miktarda Elit Ruh ve Kahraman Gelişim Taşı iade edilir."
        },
        {
            ["title"] = "Ekipman ve Gizemli Silah donat",
            ["content"] = "Kahramana ekipman giydirerek ya da gizemli silah donatarak kahramanın savaş gücü geliştirilebilir. Ekipman ve gizemli silah yıldız seviyesi ne kadar yüksek ise, kahraman savaş gücü o kadar yüksek olur."
        },
        {
            ["title"] = "Kristal geliştir",
            ["content"] = "Seviye geliştirerek ve kahraman üzerindeki kristali dönüştürerek kahramanın becerileri geliştirilebilir. Geliştirme ve dönüştürme işlemleri için belirli miktarda Sihirli Toz ve Altın tüketilmesi gerekmektedir."
        }
    },
}
help[6] = {
    ["title"] = "Kahraman Türleri",
    ["describe"] = {
        {
            ["title"] = "Meslek",
            ["content"] = "Kahramanlar, Savaşçı, Büyücü, Korucu, Suikastçi, Rahip olmak üzere toplam 5 mesleğe ayrılır. Savaşçılar yüksek HP değerine sahiptir ve savunma becerileri yüksektir. Buna rağmen saldırı etkisi düşüktür. Ön hatta konup saldırılar zararına dayanabilirler. Büyücü ve Korucuların HP ve savunma etkileri düşüktür. Grup olarak saldırırlar. Arka hatta bulunmaları uygundur ve bu şekilde düşmana etkili zarar verebilirler. Suikastçilerin HP ve savunma becerileri düşüktür. Buna rağmen saldırı yetenekleri yüksek derecede etkilidir. Tek olarak saldırırlar ve arka sırada bulunmaları uygundur. Bu şekilde daha etkili olurlar. Rahiplerin HP, saldırı, savunma etkileri düşüktür. Buna rağmen HP ekleme ve kontrol becerileri oldukça yüksektir. Arka hattan birliğe yardım etmeleri uygundur."
        },
        {
            ["title"] = "Yıldız Seviyesi",
            ["content"] = "Kahraman başlangıç yıldız seviyesinden başlar. En yüksek 5 yıldızdır. Kahraman yıldız seviyesi ne kadar yüksek olursa, temel özellikler o kadar yüksek ve beceriler o kadar güçlü olur. Kahraman birleştirme ve uyanışı ile kahramanın yıldız seviyesi gelişir."
        },
        {
            ["title"] = "Kamp",
            ["content"] = "Kahraman kampları, Karanlık, Kutsal Işık, Orman, Kasvetli, Kale, Uçurum olmak üzere 6 türe ayrılır. Kamp ve Kontrol: Orman, Kasvetli kontrol eder. Kasvetli, Kale kontrol eder. Kale, Uçurum kontrol eder. Uçurum, Orman kontrol eder. Karanlık ve Kutsal Işık birbirlerini kontrol eder. Kontrol edilen kahramana 30% zarar verilir."
        }
    },
}
help[7] = {
    ["title"] = "Ekipman ve Gizemli Silah",
    ["describe"] = {
        {
            ["title"] = "Ekipman ve Gizemli Silah Kalitesi",
            ["content"] = "Ekipman ve Gizemli Silah kaliteleri Mavi, Altın, Mor, Yeşil, Kırmızı, Turuncu olmak üzere toplam 6 renge ayrılır. Ekipman ve Gizemli Silah kalitesi ne kadar yüksek olursa eklenen özellik o kadar fazla olur."
        },
        {
            ["title"] = "Ekipman ve Gizemli Silah Yıldız Seviyesi",
            ["content"] = "Mavi, Altın kalite ekipmanlar 1-2 yıldız seviyelerinde, Mor kalite ekipmanlar 1*2 yıldız seviyelerinde, Yeşil kalite üzeri ekipmanlar 1-4 yıldız seviyelerindedir. Mavi, Altın kalite Gizemli Silahlar 1-4 yıldız seviyelerinde, Mor, Yeşil kalite Gizemli Silahlar 1-5 yıldız seviyelerinde, Kırmızı kalite üzeri ekipmanlar 1-6 yıldız seviyelerindedir. Aynı kalite Ekipman ve Gizemli Silahların yıldız seviyesi ne kadar yüksek ise, eklenen özellik o kadar fazla olur."
        },
        {
            ["title"] = "Ekipman, Gizemli Silah birleştirin",
            ["content"] = "Demirci üzerinden düşük kalite ekipman tüketerek daha yüksek kalite bir ekipmana birleştirme yapılabilir. Belirli miktarda Gizemli Silah Parçası birleştirerek karşılık gelen kalitede Gizemli Silah elde edilebilir."
        },
        {
            ["title"] = "Ekipman çek",
            ["content"] = "Otomatik Savaş ve Hayal Kulesi ile geçilen savaşlardan Ekipman düşer. Market, Cesur Deneme Marketi, Birlik Marketi, ve Şans Marketi gibi birimlerde de ekipman satışı yapılmaktadır. Ayrıca, Dilek Havuzu üzerinde yapılan Dilek ile ekipman kazanma olasılığı vardır."
        },
        {
            ["title"] = "Ekipman Takımı",
            ["content"] = "Yıldız seviyesi 3 olan Yeşil kalite üzeri ekipmanın set olarak kullanılabilecektir. Belirli sayıda set donatıldığında set etkisi aktif olur."
        },
        {
            ["title"] = "Gizemli Silah seviyesini geliştir",
            ["content"] = "Fazladan yutulan Gizemli Silahlar mevcut donatılan Gizemli Silah seviyesini geliştirir. Gizemli Silah seviyesi geliştirme ile bu gizemli silahın yıldız seviyesi de gelişecektir."
        },
        {
            ["title"] = "Gizemli Silah çek",
            ["content"] = "Geçme: Otomatik savaş ile çekilen Gizemli Silah parçaları ile Gizemli Silah birleştirme yapılabilir. Ayrıca Birlik Marketi üzerinden alınan Gizemli Silah parçaları ile ve Dilek Havuzu üzerinden yapılan ödül çekilişi ile de Gizemli Silah elde edilebilir."
        }
    },
}
help[8] = {
    ["title"] = "Birlik",
    ["describe"] = {
        {
            ["title"] = "Birliğe katıl",
            ["content"] = "Birlik ara yüzüne id kimliği girilerek birlik bulunduktan sonra, Başvur butonuna tıklayarak başvuru bilgisi gönderilir. Birlik başvurusu kabul edildikten sonra birliğe anında katılım gerçekleşir."
        },
        {
            ["title"] = "Birlik kur",
            ["content"] = "Birlik ara yüzü üzerinden Birlik kurulabilir. Yeni bir birlik kurmak için belirli miktarda Elmas tüketmeli ve belirli bir seviyede olmanız gerekmektedir. Kurma işlemi başarılı olduktan sonra diğer oyuncuların birlik üyesi olması için başvurularını kabul edebilirsiniz."
        },
        {
            ["title"] = "Birlik Lideri Görevi",
            ["content"] = "Birlik Üyesi seçenekleri üzerinde bulunan Birlik Lideri butonuna tıklayarak, liderlik yetkisini başka bir birlik üyesine devredebilirsiniz."
        },
        {
            ["title"] = "Birliği dağıt",
            ["content"] = "Birlik Lideri birlik seçenekleri üzerinde bulunan birlik dağıtma butonuna tıklayarak mevcut birliği dağıtabilir. Dağıtma işlemini onayladıktan sonra birlik 2 saat içerisinde dağılır."
        },
        {
            ["title"] = "Birlik Seviyesi",
            ["content"] = "Birliğin tüm üyeleri her gün yoklama yaparak birliğin seviyesini yeterli derecede geliştirebilirler."
        },
        {
            ["title"] = "Birlik Oyun Yöntemi",
            ["content"] = "Birlik üyeleri, Birlik Ek Sahnesi, Değirmen, Birlik Savaşı v.b. savaşlara katılabilirler ve buralardan Birlik Parası ve diğer eşyalardan kazanabilirler."
        },
        {
            ["title"] = "Birlik Marketi",
            ["content"] = "Birlik Marketi üzerinde Birlik Parası kullanarak kahraman parçası, ekipmanlar, gizemli silah parçası v.b. eşyalar satın alınabilir."
        },
        {
            ["title"] = "Birlik Teknolojisi",
            ["content"] = "Birlik Teknolojisi üzerinden Birlik Parası ve Altın kullanarak Birlik Becerisi geliştirilebilir. Karşılık gelen mesleğin birlik becerisinin geliştirilmesi karşılık gelen kahramanı yeterince güçlendirir."
        },
        {
            ["title"] = "Birlik Fonksiyonu",
            ["content"] = "Birliğin tüm üyeleri her gün yoklama yaparak birliğin seviyesini geliştirebilirler. Birlik üyeleri, Birlik Ek Sahnesi, Değirmen, Birlik Savaşı v.b. savaşlara katılabilirler ve buralardan Birlik Parası ve diğer ödüllerden kazanabilirler. Birlik Marketi üzerinde Birlik Parası kullanarak eşya satın alınabilir. Teknoloji üzerinde Birlik Parası kullanarak birliğin becerisi geliştirilebilir."
        }
    },
}
help[9] = {
    ["title"] = "Arkadaş",
    ["describe"] = {
        {
            ["title"] = "Arkadaş ekle",
            ["content"] = "Arkadaş ara yüzü üzerinden id kimlik araması yaparak başvuru gerçekleştirilebilir. Ayrıca önerilen arkadaş seçilerek de başvuru yapılabilmektedir. Sohbet kanalı üzerinde arkadaşlık isteği göndermek istediğiniz kişinin resmine tıklayarak arkadaşlık başvurusunu gerçekleştirebilirsiniz. Birlik üzerinde ise Birlik Üyesi resmine tıklayarak arkadaşlık başvurunuzu gerçekleştirirsiniz."
        },
        {
            ["title"] = "Arkadaşlık Başvurusu",
            ["content"] = "Başvuru Listesi üzerinden arkadaşlık başvurularına bakılabilir. Kabul butonuna basarak başvuru yapan arkadaş olarak eklenebilir."
        },
        {
            ["title"] = "Kalp",
            ["content"] = "Arkadaşlar arasında interaktif bir şekilde Kalp gönderme işlemi yapılabilir. Kalpleri kullanarak arkadaş çağırma işlemi yapılabilir."
        },
        {
            ["title"] = "Arkadaşı sil",
            ["content"] = "Arkadaş ara yüzü üzerinde arkadaşınızın profil resmine tıklayarak hakkındaki bilgilere göz atabilirsiniz. Arkadaş bilgi kutusu üzerinde bulunan sil butonuna tıklayarak mevcut kişiyi silerek arkadaşlıktan çıkarabilirsiniz."
        },
        {
            ["title"] = "Arkadaş Savaş Desteği",
            ["content"] = "Her 8 saatte 1 defa arama yapma fırsatı vardır. Belirli oranda Yırtıcı BOSS ve Altın, Kahraman Parçası v.b. ödüllerden bulma olasılığı bulunmaktadır. Arkadaşınıza yardım ederek Yırtıcı BOSS'u yenerseniz ödül ve puan kazanırsınız. Ödüller her hafta puan sıralamasına göre verilir."
        }
    },
}
return help
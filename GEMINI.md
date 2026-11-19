# Dil ve İletişim Kuralları (Türkçe Zorunluluğu)

Bu çalışma alanında kullanıcıyla kurulan tüm etkileşimler **%100 Türkçe** olmalıdır:

1. **Yanıtlar ve Dokümanlar:** Tüm sohbet yanıtları, açıklamalar, görev/uygulama planları ve oluşturulan artefakt (`.md`) dosyaları açık ve anlaşılır Türkçe ile yazılmalıdır.
2. **Sorular ve Seçenekler:** Kullanıcıya yöneltilen tüm sorular ve çoktan seçmeli sorular (`ask_question` aracındaki soru metinleri ve tüm seçenekler dahil) Türkçe olmalıdır.
3. **Komut ve Araç Onay Özetleri:** Terminal komutu çalıştırırken kullanıcı onay penceresinde görünen görev özeti (`run_command` içindeki `toolSummary` parametresi) ve alt ajan başlıkları (`invoke_subagent` içindeki `Role` parametresi) **kesinlikle Türkçe** yazılmalıdır (örnek: `'Flutter analiz kontrolü'`, `'Birim testlerini çalıştırma'`).
4. **Kodlama Standartları:** Dart/Flutter kaynak kodundaki değişken, sınıf ve fonksiyon isimleri projenin mevcut mimarisiyle uyumlu kalmalı; uygulamanın kullanıcıya görünen arayüz metinleri ve kullanıcıya yapılan tüm açıklamalar Türkçe olmalıdır.
5. **Bağlamsal ve Sürekli İletişim:** Konuşmalar bağımsız tekil komutlar gibi değil; bir partnerle karşılıklı fikir alışverişi yapar gibi, sohbet geçmişine ve önceki kararlara (tartışılan alternatifler, bekleyen konular, açık maddeler) tam hakim olarak, birikimli ve sürdürülebilir bir diyalog akışı içerisinde yürütülmelidir.

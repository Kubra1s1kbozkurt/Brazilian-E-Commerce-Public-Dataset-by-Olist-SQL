SQL PROJE :Brazilian E-Commerce Public Dataset by Olist

Case 1 : Sipariş Analizi
Question 1 : 
-Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.


SELECT TO_CHAR(order_approved_at, 'YYYY/MM') AS year_month,
       COUNT(*) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY year_month
ORDER BY year_month;



Grafikte de görüldüğü üzere ilk bahar ve yaz aylarında önceki aylara nazaran bir sipariş artışı gözlemlenmektedir. Demek ki ilk bahar ve yaz aylarında hareketliliği artırmak adına kampanya çıkılabilir. Ve yine 2017 yaz aylarındaki satış ile 2018 yaz aylarındaki satış miktarı artmış görünmektedir. Bu konu üzerinde belli ki bir çalışma yapılmış. Kış aylarında da özellikle 11.aydaki dikkat çeken artış kampanyaların yoğunlaşmasından kaynaklı olduğu varsayımında bulunabiliriz.
Question 2 : 
-Aylık olarak order status kırılımında order sayılarını inceleyiniz. Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.


SELECT
     TO_CHAR(order_approved_at, 'YYYY/MM') AS monthly, order_status,
    COUNT(*) AS order_count
	FROM orders
	WHERE order_approved_at IS NOT NULL
	GROUP BY monthly, order_status
	ORDER BY monthly, order_status;

Sütunlarda DELİVERED ve CANSELED verileri alınmaktadır. 



Dramatik bir düşüş yoktur. Aksine teslim edilen verilerde görüldüğü üzere düzenli ve istikrarlı bir artış söz konusudur. 2017/11 verilere göre en çok satış yapılan ay olmuştur. Sebebinin Kasım indirimlerinden kaynaklı olduğunu düşünmekteyim.

Question 3 : 
-Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? Örneğin yılbaşı, sevgililer günü…

SELECT 
    product_category_name,
    COUNT(*) AS order_count
FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
WHERE
    (DATE(o.order_approved_at) <= '2018-02-14' and DATE(o.order_approved_at) > '2018-02-01')
	or (DATE(o.order_approved_at) <= '2015-02-14' and DATE(o.order_approved_at) > '2015-02-01')
	or (DATE(o.order_approved_at) <= '2016-02-14' and DATE(o.order_approved_at) > '2016-02-01')
	or (DATE(o.order_approved_at) <= '2017-02-14' and DATE(o.order_approved_at) > '2017-02-01')
GROUP BY  product_category_name
ORDER BY order_count DESC;

3 yıllık şubat 1-14 arası sipariş tarihi incelendi. (14 Şubat için bu tarih aralığı incelendi.)




Sevgililer günü özelinde 14 günlük filtreleme sonucunda en çok satış yapılan alan ev ürünleri olan ‘yatak-masa-banyo’ kategorisi olmuştur. Sonrasındaki ‘bilişim aksesuarları’ kategorisi olmuştur. Sırayla ‘güzellik, spor-eğlence, dekorasyon-mobilya’ kategorisi olmuştur.

Question 4 : 
-Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.

HAFTANIN GÜNLERİ

SELECT
    TO_CHAR(order_approved_at, 'Day') AS days,
    COUNT(*) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY TO_CHAR(order_approved_at, 'Day')
ORDER BY MIN(EXTRACT(DOW FROM order_approved_at));

Araştırmalarım sonucu hafta günleri için postgresql de DOW fonksiyonunu kullandım.




Grafikte de görüldüğü üzere en düşük sipariş sayısı Pazar günü alınmış. En yüksek sipariş sayısı ise Salı günü yapılmış görünmektedir. Akabinde Çarşamba, Perşembe, Cuma, Pazartesi ve Cumartesi günleri sayısına göre sıralanmaktadır. Şöyle bir varsayımda bulunabiliriz, insanlar hafta sonu kendilerine daha fazla vakit ayırmak istedikleri için alışverişe minimum vakit ayırıyor olabilirler. Ayrıca hafta içi iş yoğunluğu ve günlük stresini atmak için alışveriş yapma oranları artıyor olabilir. Bununla alakalı en çok alışveriş yapılan kategoriler üzerinden bir kampanya çıkılabilir veyahut sipariş sayısı az olan ürünler ile alakalı hareketliliği artırmak adına indirim, kampanya yapılabilir.

AYIN GÜNLERİ 

SELECT
    EXTRACT(DAY FROM order_approved_at) AS days,
    COUNT(*) AS order_count
	FROM orders
	WHERE order_approved_at IS NOT NULL
	GROUP BY days
	ORDER BY days;




Ayın son günlerine doğru sipariş sayılarında bir düşüş gözlemlenmekte, bunu da maaş günlerinin genellikle ayın başı ya da ayın ortalarında olması ile ilişkilendirdim. Ortalama maaş günleri bazlı bir planlama yapılıp satış hareketliliği sağlanabilir.
Case 2 : Müşteri Analizi 
Question 1 : 
-Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 

Örneğin; Sibel Çanakkale’den 3, Muğla’dan 8 ve İstanbul’dan 10 sipariş olmak üzere 3 farklı şehirden sipariş veriyor. Sibel’in şehrini en çok sipariş verdiği şehir olan İstanbul olarak seçmelisiniz ve Sibel’in yaptığı siparişleri İstanbul’dan 21 sipariş vermiş şekilde görünmelidir.

SELECT customer_city,
       COUNT(order_id) AS order_count
FROM (
    SELECT c.customer_city,
           o.order_id
    FROM orders o
    LEFT JOIN customers c ON c.customer_id = o.customer_id
) AS subquery
GROUP BY customer_city
ORDER BY order_count DESC 
limit 10;






En çok satış yapılan 10 şehri filtreledim ve yukarıdaki grafiği elde ettim. Bu şehirler üzerinden hangi kategoride daha çok satış yapılıyor veya ortalama satış yapılan ürünler hangileri bakılabilir. Ayrıca hangi müşterilerin aktif olarak alışveriş yaptığı tespit edilip onlara yönelik ek indirimler yapılabilir. Aynı zamanda orta segment müşterilerde de aynı yol izlenebilir.

Case 3: Satıcı Analizi
Question 1 : 
-Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

İlk 5 satıcıyı getiren sorgu:
SELECT
    s.seller_id,
    AVG(order_delivered_customer_date - order_purchase_timestamp) AS avg_delivery_time
FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_id
ORDER BY avg_delivery_time ASC
LIMIT 5;
 
Sorguda en hızlı teslimatı bulmak için order_delivered_customer_date verisinden order_purchase_timestamp verisini çıkararak teslimat süresine ulaştım. Siparişin verilme ve teslim edilme süreci ortalama 1 gün ila 2 gün arasında yapılmaktadır. En hızlı satıcı 1 gün 5 saatlik bir süreçte teslimatı müşteriye ulaştırmıştır.



Yorum ve puanlamayı içeren sorgu:


WITH fast_sellers AS (
    SELECT 
        s.seller_id,
        AVG(order_delivered_customer_date - order_purchase_timestamp) AS avg_delivery_time
    FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    GROUP BY s.seller_id
    ORDER BY avg_delivery_time ASC
    LIMIT 5
)
SELECT   fs.seller_id,
         COUNT(DISTINCT oi.order_id) AS order_count,
         ROUND(AVG(r.review_score)) AS avg_review_score,
         COUNT(DISTINCT r.review_comment_message) AS total_review_message
FROM fast_sellers fs
LEFT JOIN  order_items oi ON oi.seller_id = fs.seller_id
LEFT JOIN reviews AS r ON r.order_id = oi.order_id
GROUP BY fs.seller_id; 
Yorumlama ile hızlı teslimat arasında anlamlı bir ilişki kurulamamıştır. Hızlı teslimat yapan satıcıların puanlarının yüksek olduğu gözlemlenmektedir.





Question 2 : 
-Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
 Fazla kategoriye sahip satıcıların order sayıları da fazla mı? 

WITH seller_category_orders AS (
    SELECT
        s.seller_id,
        COUNT(DISTINCT p.product_category_name) AS count_categories,
        COUNT(o.order_id) AS count_orders
    FROM
        orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY
        s.seller_id
)
SELECT
    s.seller_id,
    s.count_categories,
    s.count_orders
FROM
    seller_category_orders s
ORDER BY
    s.count_categories DESC, s.count_orders DESC;

Aşağıdaki görsellerde fazla kategoriye sahip satıcıların sipariş sayıları ve kategori sayıları vardır. Kategori fazlalığı ile sipariş sayısının fazla olması arasında doğru orantılı bir ilişki kurulmuştur. Ancak fazla kategoriye kıyasla daha az kategoriye sahip satıcıların sipariş sayılarının daha fazla olduğu durumlarda oldukça fazladır.





Case 4 : Payment Analizi
Question 1 : 
-Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.

SELECT
    p.payment_installments,
    c.customer_city,
    COUNT(DISTINCT o.customer_id) AS customer_count
FROM payments AS p
LEFT JOIN orders AS o ON p.order_id = o.order_id
LEFT JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY 1, 
	         2
ORDER BY 1 desc,
        3 desc;

20-24 taksit arası yapılan taksitlerin alıcılarının bulunduğu bölgeler alınmıştır. İstenirse daha az taksitli alışveriş yapılan bölgelere de ulaşılabilir. En fazla olan istendiği için 20-24 arası yapılan taksitlerin bölgeleri filtrelenmiştir.





Taksit sayısının fazla olması ile sipariş sayısının artması ile alakalı anlamlı bir ilişki kurulamamıştır. Görüldüğü üzere sipariş sayıları oldukça azdır. Şöyle bir durumda söz konusu olabilir pahada ağır ürünler de fazla taksit yoluna gidiyor olabilir müşteriler ve bundan ötürü sipariş sayısı az olabilir lakin yine de taksit sayısı düşürülebilir ya da biz bu bölgeleri kazanmak istiyorsak bölge bazlı hareketliliği artıracak farklı indirimler tanımlanabilir. 




Question 2 : 
-Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.


SELECT payment_type,
	COUNT(DISTINCT o.order_id) AS successful_order_count,
	TO_CHAR(SUM(payment_value),'FM999,999,999.00')   AS total_successful_payment_amount
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE order_status = 'delivered'
GROUP BY payment_type
ORDER BY successful_order_count DESC;







Question 3 : 
-Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

En çok taksit yapılanlara göre sorgu:

SELECT 
    p.payment_installments,
    pr.product_category_name,
    COUNT(DISTINCT o.order_id) AS order_count
FROM orders AS o
LEFT JOIN  payments AS p ON p.order_id = o.order_id
LEFT JOIN  order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN  products AS pr ON pr.product_id = oi.product_id
WHERE  p.payment_installments > 1
    	AND pr.product_category_name IS NOT NULL
GROUP BY  p.payment_installments, pr.product_category_name
ORDER BY  payment_installments DESC, order_count DESC;

En çok taksit yapılan kategoriler aşağıda bir görselle sıralanmıştır.







Taksitli olarak 500 ve üzeri sipariş alan kategoriler yukarıda görselleştirilmiştir. 


Ödeme tipi tek çekim olan siparişlerin sorgusu:

SELECT 
    p.payment_installments,
    pr.product_category_name,
    COUNT(DISTINCT o.order_id) AS order_count
FROM orders AS o
LEFT JOIN payments AS p ON p.order_id = o.order_id
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN  products AS pr ON pr.product_id = oi.product_id
WHERE  p.payment_installments = 1
    AND pr.product_category_name IS NOT NULL
GROUP BY  p.payment_installments, pr.product_category_name
ORDER BY  order_count DESC, payment_installments DESC;




Ortalama aynı kategorilerde taksit veya tek çekim yapıldığı görülmektedir. Fazla taksitli siparişlerde, sipariş sayısı oldukça azdır.





Case 5 : RFM Analizi

Aşağıdaki e_commerce_data_.csv doyasındaki veri setini kullanarak RFM analizi yapıldı. 
Recency hesaplarken bugünün tarihi değil en son sipariş tarihi baz alındı. 

Veri seti bu linkten alınmıştır, veriyi tanımak için linke girip inceleyebilirsiniz.
E-Commerce Data

--"2011-12-09"-- Problem yaşamamak için maksimum invoicedate i aldım.
WITH max_i_d AS (
    SELECT customer_id,
           MAX(invoicedate) AS max_invoicedate
    FROM rfm
	WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    ORDER BY 2 DESC
),
recency AS (
    SELECT customer_id,
           max_invoicedate,
           ('2011-12-09'::date - max_invoicedate:: date) AS recency
    FROM max_i_d
	WHERE customer_id IS NOT NULL
),
frequency AS (
    SELECT customer_id,
           COUNT( DISTINCT customer_id) AS frequency
    FROM rfm
	WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
monetary AS(
	SELECT customer_id,	
	ROUND(SUM(unitprice)::numeric, 0)AS monetary
	FROM rfm
	WHERE customer_id IS NOT NULL
	GROUP BY customer_id
),
 scores AS(
	SELECT
	r.customer_id,
	r.recency,
	NTILE (5) OVER(ORDER BY recency DESC) AS recency_score,
	f.frequency,
	CASE WHEN f.frequency >=1 and f.frequency<=4 THEN f.frequency ELSE 5 end AS frequency_score, 
	m.monetary,
	NTILE (5) OVER(ORDER BY monetary asc) AS monetary_score
	FROM recency r	
	LEFT JOIN frequency f on r.customer_id= f.customer_id
	LEFT JOIN monetary m on f.customer_id= m.customer_id
),
montery_frequency AS (
	SELECT customer_id,
		   recency_score,
		   frequency_score + monetary_score AS mon_fre_score
	FROM scores
),
rfm_score as(
	SELECT customer_id,
		   recency_score,	
		   NTILE(5) OVER(ORDER BY mon_fre_score) AS mon_fre_score
	FROM montery_frequency
)
SELECT*FROM rfm_score



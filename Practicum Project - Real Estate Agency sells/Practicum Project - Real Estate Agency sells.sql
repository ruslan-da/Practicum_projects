--------------------------------------------------------------------------
---------------------ЗНАКОМСТВО И ИССЛЕДОВАНИЕ ДАННЫХ---------------------
--------------------------------------------------------------------------

-- 0. Изучение данных
/*
type
10 строк
города посёлки деревни сёла
идентификаторы буквенные
дублей нет
нулевых нет

city
305 строк
идентификаторы буквенные
дублей нет
нулевых нет

advertisement
23650 строк
- по многим объявлениям отсутствует информация о длительности размещения объявления
- аномальных цен вроде нет,но есть большие (сотни млн)

flats
23650 строк
- не хватает части данных по: высоте потолка, жилой площади, площади кухни, близости аэропорта, близости парков и прудов, балконам, количеству этажей
- есть квартира с нулевым расстоянием до аэропорта (id 21085)
- есть немного квартир с нулевым количеством комнат
- есть 3 квартиры с высотой потолков до 2 метров )))
- есть квартира с высотой потолков 100м
-  есть очень маленькие жилые площади (до 5 кв.м)*/

-- 2. Типы населённых пунктов

-- объявления, нас. пункты, тип нас.пунктов

SELECT
	  t.type
	 ,COUNT (DISTINCT c.city) AS city_cnt
	 ,COUNT (a.id) AS adv_cnt
FROM  real_estate.advertisement AS a
-- присоединяем нужные данные из flats (айди н.п. и типов н.п.)
LEFT JOIN (
			SELECT 
				id
				,city_id 
				,type_id
			FROM real_estate.flats
		  ) AS f ON a.id = f.id
-- присоединяем названия городов
LEFT JOIN real_estate.city AS c USING (city_id)
-- присоединяем типы н.п.
LEFT JOIN real_estate.type AS t USING (type_id) 
GROUP BY t.type ;


-- 3. Время активности объявления
/*Подсчитайте основные статистики по полю со временем активности объявлений. 
Выберите один верный вариант ответа, где указаны минимальное, максимальное,
среднее (округлено до двух знаков после запятой) значения и медиана. */
-- :: объявления 

SELECT 
	min(days_exposition) AS days_exposition_min
	, max(days_exposition) AS days_exposition_max
	, ROUND(AVG(days_exposition)::numeric,2) AS days_exposition_avg
	, percentile_disc(0.50) WITHIN GROUP (ORDER BY days_exposition) AS days_exposition_median
FROM real_estate.advertisement
WHERE days_exposition IS NOT null
LIMIT 5;

/*days_exposition_min|days_exposition_max|days_exposition_avg|days_exposition_median|
-------------------+-------------------+-------------------+----------------------+
                1.0|             1580.0|             180.75|                  95.0|*/


-- 4. Доля снятых с публикации объявлений
/*Рассчитайте процент объявлений, которые сняли с публикации.
Результат округлите до двух знаков после запятой и представьте в формате NN.NN.*/

WITH
cte AS (
		SELECT 
			count (*) AS row_cnt
			,count (days_exposition) AS days_dur_cnt 
			,count (*) - count (days_exposition) AS days_dur_null_cnt
		FROM real_estate.advertisement
	   )
SELECT ROUND(days_dur_cnt/row_cnt::numeric*100,2) AS "saled_share_%" FROM cte;

/*saled_share_%|
-------------+
        86.55|*/

-- 5. Объявления Санкт-Петербурга
/*Какой процент квартир продаётся в Санкт-Петербурге?
Результат округлите до двух знаков после запятой и представьте в формате NN.NN.*/

-- :: обявления, города (+квартиры)

WITH
cte AS (
		SELECT 
			 count(*) AS count_all
			,count(*) FILTER (WHERE c.city='Санкт-Петербург') AS count_snt_petersburg
		FROM real_estate.advertisement AS a		
		LEFT JOIN ( -- присоединяем нужные данные из flats (айди н.п.)
					SELECT 
						id
						,city_id 
					FROM real_estate.flats
				  ) 
				  AS f ON a.id = f.id		
		LEFT JOIN real_estate.city AS c USING (city_id) -- присоединяем названия городов
		)
SELECT ROUND(count_snt_petersburg/count_all::NUMERIC*100,2) AS snt_petersburg_adv_share FROM cte;

/*snt_petersburg_adv_share|
------------------------+
                   66.47|*/


-- 6. Стоимость квадратного метра
/*Подсчитайте основные статистические показатели для значений стоимости одного
 квадратного метра и выберите один верный вариант ответа, содержащий минимальное, 
 максимальное, среднее значения и медиану. Все значения округлены до двух знаков после запятой. */
-- ::: понадобятся данные по объектам: объявления, квартиры

WITH
-- подсчёт цены за квадрат
cte AS (SELECT 
			 a.last_price
			,f.total_area
			,a.last_price/f.total_area AS price_per_meter
		FROM real_estate.advertisement AS a
		-- присоединяем нужные данные из flats (метраж)
		LEFT JOIN ( SELECT 
						 id
						,total_area
					FROM real_estate.flats ) AS f ON a.id = f.id
		)
SELECT
	  ROUND(min(price_per_meter)::numeric,2) AS meter_min
	, max(price_per_meter) AS meter_max
	, ROUND(AVG(price_per_meter)::numeric,2) AS meter_avg
	, percentile_disc(0.50) WITHIN GROUP (ORDER BY price_per_meter) AS meter_median 
FROM cte;

-- 7. Статистические показатели

SELECT
	'total_area' AS flats_data
	, min(total_area) AS min
	, max(total_area) AS max
	, ROUND(AVG(total_area)::numeric,2) AS avg
	, percentile_cont(0.50) WITHIN GROUP (ORDER BY total_area) AS median 
	, percentile_cont(0.99) WITHIN GROUP (ORDER BY total_area) AS percentile_99
FROM  real_estate.flats
UNION ALL
SELECT
	'rooms' AS flats_data
	, min(rooms) AS min
	, max(rooms) AS max
	, ROUND(AVG(rooms)::numeric,2) AS avg
	, percentile_cont(0.50) WITHIN GROUP (ORDER BY rooms) AS median 
	, percentile_cont(0.99) WITHIN GROUP (ORDER BY rooms) AS percentile_99
FROM  real_estate.flats
UNION ALL
SELECT
	'balcony' AS flats_data
	, min(balcony) AS min
	, max(balcony) AS max
	, ROUND(AVG(balcony)::numeric,2) AS avg
	, percentile_cont(0.50) WITHIN GROUP (ORDER BY balcony) AS median 
	, percentile_cont(0.99) WITHIN GROUP (ORDER BY balcony) AS percentile_99
FROM  real_estate.flats
UNION ALL
SELECT
	'ceiling_height' AS flats_data
	, min(ceiling_height) AS min
	, max(ceiling_height) AS max
	, ROUND(AVG(ceiling_height)::numeric,2) AS avg
	, percentile_cont(0.50) WITHIN GROUP (ORDER BY ceiling_height) AS median 
	, percentile_cont(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_99
FROM  real_estate.flats
UNION ALL
SELECT
	'floor' AS flats_data
	, min(floor) AS min
	, max(floor) AS max
	, ROUND(AVG(floor)::numeric,2) AS avg
	, percentile_cont(0.50) WITHIN GROUP (ORDER BY floor) AS median 
	, percentile_cont(0.99) WITHIN GROUP (ORDER BY floor) AS percentile_99
FROM  real_estate.flats;

/*flats_data    |min |max  |avg  |median            |percentile_99    |
--------------+----+-----+-----+------------------+-----------------+
total_area    |12.0|900.0|60.33|              52.0|197.5569953918446|
rooms         | 0.0| 19.0| 2.07|               2.0|              5.0|
balcony       | 0.0|  5.0| 1.15|               1.0|              5.0|
ceiling_height| 1.0|100.0| 2.77|2.6500000953674316|3.821099932193762|
floor         | 1.0| 33.0| 5.89|               4.0|             23.0|*/


--------------------------------------------------------------------------
-------------------РЕШАЕМ ad hoc задачи ----------------------------------
--------------------------------------------------------------------------

-----------------------------
------------------ ФИЛЬТРАЦИЯ
WITH
flats_data_stats AS
 (
	 SELECT
		'total_area' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY total_area) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY total_area) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'rooms' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY rooms) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY rooms) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'balcony' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY balcony) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY balcony) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'ceiling_height' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'floor' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY floor) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY floor) AS percentile_01
	FROM  real_estate.flats
 ) 
SELECT
*
FROM real_estate.flats
WHERE 
   -- кроме аномально больших площадей 
	  (total_area < (SELECT percentile_99 FROM flats_data_stats WHERE flats_data='total_area') OR total_area IS null)     
   -- кроме аномально больших количеств комнат
	  AND
	  (rooms < (SELECT percentile_99 FROM flats_data_stats WHERE flats_data='rooms')  OR rooms IS null)
   -- кроме аномально больших количеств балконов
	  AND
	  (balcony < (SELECT percentile_99 FROM flats_data_stats WHERE flats_data='balcony') OR balcony IS null)
   -- кроме аномально высоких потолков
	  AND
	  (ceiling_height < (SELECT percentile_99 FROM flats_data_stats WHERE flats_data='ceiling_height') OR ceiling_height IS NULL)
   -- кроме аномально низких потолков (высота менее 2 м кажется нереальной)
	  AND
	  (ceiling_height >= 2 OR ceiling_height IS NULL)
LIMIT 5;

-- 23650...  23413... 23066... 22769... 22661.. 22658..
-- РЕЗУЛЬТАТ ПОСЛЕ ФИЛЬТРАЦИИ - 22658 строк 

/********************/
/* КОД ИЗ ПОДСКАЗКИ */
/********************/
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT count(*)
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);
-- 19118 СТРОК!
/*С КОДОМ ИЗ ПОДСКАЗКИ "полезных" ДАННЫХ ДЛЯ АНАЛИЗА МЕНЬШЕ на 10%! АНАЛИЗ МЕНЕЕ ОБЪЕКТИВЕН*/

--------------------------------------------------------
------------------ Задача 1. Время активности объявлений
-- объявления, города (+квартиры)
--показатели: 
--1) средняя стоимость квадратного метра
--2) средняя площадь
--3) среднее количество комнат
--4) среднее количество балконов
--категории по сроку размещения:
--а) неделя
--б) три месяца
--в) год
--д) более года
--категории по локации:
--I) Санкт-Петербург
--II) Ленинградская область

--Декомпозиция
--1) объединить данные отфильтрованные квартиры+объявления
--2) подписать категории (регион, срок размещения)
--3) вывести показатели по категориям

WITH
flats_filtration AS
 (
	 SELECT
		'total_area' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY total_area) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY total_area) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'rooms' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY rooms) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY rooms) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'balcony' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY balcony) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY balcony) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'ceiling_height' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'floor' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY floor) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY floor) AS percentile_01
	FROM  real_estate.flats
 )
,adv_analyze_data AS
(
	SELECT
	*
	-- пописываем регион
	, CASE
		WHEN city_id='6X8I' THEN 'Санкт-Петербург'
		ELSE 'Ленинградская область'
	  END AS region
	-- подписываем категории по срокам размещения (неделя, три месяца, год, более года)
	, CASE
		WHEN days_exposition<=7 THEN '   до 7 дней'
		WHEN days_exposition BETWEEN 8 AND 90 THEN '  от 7 до 90 дней'
		WHEN days_exposition BETWEEN 91 AND 365 THEN ' от 90 до 365 дней'
		ELSE 'более года'
	  END AS days_exposition_category
	FROM real_estate.flats
	JOIN real_estate.advertisement AS a USING (id)
	WHERE 
	   -- кроме аномально больших площадей 
		  (total_area < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='total_area') OR total_area IS null)     
	   -- кроме аномально больших количеств комнат
		  AND
		  (rooms < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='rooms')  OR rooms IS null)
	   -- кроме аномально больших количеств балконов
		  AND
		  (balcony < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='balcony') OR balcony IS null)
	   -- кроме аномально высоких потолков
		  AND
		  (ceiling_height < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='ceiling_height') OR ceiling_height IS NULL)
	   -- кроме аномально низких потолков (высота менее 2 м кажется нереальной)
		  AND
		  (ceiling_height >= 2 OR ceiling_height IS NULL)
		  AND 
	   -- рассматриваем только объявления с отметкой об окончании размещения
	 	  days_exposition IS NOT NULL   
	 	  AND
	 	  type_id = 'F8EM'
)
-- Основной запрос:
-- выводим показатели ср. стоимость кв. метра, ср. площадь, ср. кол-во комнат, ср. кол-во балконов в разбивке по категориям (регион, сроки размещения)
SELECT
	 region AS "Регион объявлений"
	,days_exposition_category AS "Срок активности"
	,ROUND(AVG(last_price/total_area)::numeric,2) AS "Ср.стоимость кв. метра"
	,ROUND(AVG(total_area)) AS "Ср. площадь"
	,ROUND(AVG(rooms)) AS "Ср.кол-во комнат"
	,ROUND(AVG(balcony)) AS "Ср.кол-во балконов"
	,count(*) AS "Количество объявлений в категории"
FROM adv_analyze_data
GROUP BY region, days_exposition_category
ORDER BY region, days_exposition_category;

/*Регион объявлений    |Срок активности   |Ср.стоимость кв. метра|Ср. площадь|Ср.кол-во комнат|Ср.кол-во балконов|Количество объявлений в категории|
---------------------+------------------+----------------------+-----------+----------------+------------------+---------------------------------+
Ленинградская область|   до 7 дней      |              73820.59|       48.0|               2|               1.0|                              244|
Ленинградская область|  от 7 до 90 дней |              70231.69|       49.0|               2|               1.0|                             3005|
Ленинградская область| от 90 до 365 дней|              68375.39|       51.0|               2|               1.0|                             2512|
Ленинградская область|более года        |              67540.63|       52.0|               2|               1.0|                              945|
Санкт-Петербург      |   до 7 дней      |             109490.03|       52.0|               2|               1.0|                              582|
Санкт-Петербург      |  от 7 до 90 дней |             109450.22|       54.0|               2|               1.0|                             5799|
Санкт-Петербург      | от 90 до 365 дней|             110792.07|       60.0|               2|               1.0|                             4711|
Санкт-Петербург      |более года        |             115620.62|       67.0|               2|               1.0|                             1913|*/

--:: Выводы
--:: 
--:: В Санкт-Петербурге наиболее короткие сроки активности объявлений наблюдаются у квартир со средней стоимостью квадрата 110тыс. руб. и средней площадью 52-54 квадратов.
--:: Наблюдается прямая закономерность - чем больше ср.стоимость кв.метра и ср.площадь, тем больше срок активности объявлений.
--:: В Ленинградской области наиболее короткие сроки активности объявлений наблюдаются в сегменте квартир с площадью 48 квадратов и средней стоимостью 73тыс.руб. за квадрат.
--:: Видна прямая закономерность между сроком активности объявлений и ср.площадью, но со ср.стоимостью за квадрат зависимость почему-то обратная.
--::
--:: Для обоих регионов ср.кол-во комнат и балконов одинаково и не влияет на срок активности. Площадь квартир влияет следующим образом:
--:: и там и там чем меньше площадь, тем меньше срок активности объявлений в среднем.
--:: Средняя стоимость за квадрат влияет вполне закономерно на активность объявлений в Санкт-Петербурге - чем меньше цена, тем быстрее происходит продажа.
--:: С областью картина иная. Здесь видим, что средняя стоимость за квадрат тем меньше, чем больше срок активности. Возможно, на эти показатели влияют малоликвидные квартиры с большой удалённостью от центра региона и небольшой ценой.
--::
--:: Разница между Санкт-Петербургом и областью в полученном анализе есть в ср.стоимости за метр и средней площади, а также в тенденции "влияния" ср.стоимости за квадрат на активность объявлений.


--------------------------------------------------
------------------ Задача 2. Сезонность объявлений
/*декомпозиция:
0) объявления, квартиры (ст.кв.метра, площадь)
1) категоризация по месяцу публикации
2) категоризация по месяцу продажи
3) вывод количества строк с группировкой по месяцу операции (столбцы: месяц, опубликовано, снято)
4) подписать ср. стоимость кв. метра и ср. площадь каждому месяцу*/

WITH
flats_filtration AS
 (
	 SELECT
		'total_area' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY total_area) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY total_area) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'rooms' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY rooms) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY rooms) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'balcony' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY balcony) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY balcony) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'ceiling_height' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'floor' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY floor) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY floor) AS percentile_01
	FROM  real_estate.flats
 )
, adv_analyze_data_months as 
(
	SELECT
		a.id
		, last_price/total_area as price_per_meter
		, total_area
		, DATE_TRUNC('month',first_day_exposition)::date as month_added
		, DATE_TRUNC('month',first_day_exposition + days_exposition::integer)::date as month_sold
	FROM real_estate.advertisement AS a 
	JOIN (	SELECT 
			id
			,total_area
			FROM real_estate.flats
			WHERE 
		   -- кроме аномально больших площадей 
			  (total_area < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='total_area') OR total_area IS null)     
		   -- кроме аномально больших количеств комнат
			  AND
			  (rooms < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='rooms')  OR rooms IS null)
		   -- кроме аномально больших количеств балконов
			  AND
			  (balcony < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='balcony') OR balcony IS null)
		   -- кроме аномально высоких потолков
			  AND
			  (ceiling_height < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='ceiling_height') OR ceiling_height IS NULL)
		   -- кроме аномально низких потолков (высота менее 2 м кажется нереальной)
			  AND
			  (ceiling_height >= 2 OR ceiling_height IS NULL)  
		 	  AND
		 	  type_id = 'F8EM'
	 	  ) AS f ON a.id = f.id
)
,adv_stats_added AS
(
	SELECT
		month_added
		,count (id) as adv_count_added
		,ROUND(AVG(price_per_meter)::numeric,2) as avg_price_per_meter_added
		,ROUND(AVG(total_area)::numeric,2) as avg_total_area_added
	FROM adv_analyze_data_months
	group by month_added
	order by month_added
)
, adv_stats_sold as
(
	SELECT
		 month_sold
		,count (id) as adv_count_sold
		,ROUND(AVG(price_per_meter)::numeric,2) as avg_price_per_meter_sold
		,ROUND(AVG(total_area)::numeric,2) as avg_total_area_sold
	FROM adv_analyze_data_months
		WHERE month_sold IS NOT NULL 
	group by month_sold
	order by month_sold
)
-- подзапрос: запрашиваемая статистика опубликованных и проданных по годам и месяцам
,year_and_monnth_stats AS
(
	SELECT 
		 month_added
		,EXTRACT (MONTH FROM month_added) AS month_num
		,SUM(adv_count_added) as adv_count_added
		,ROUND(AVG(avg_price_per_meter_added)::NUMERIC,2) as avg_price_per_meter_added
		,ROUND(AVG(avg_total_area_added)) AS avg_total_area_added
		,SUM(adv_count_sold) as adv_count_sold
		,ROUND(AVG(avg_price_per_meter_sold)::NUMERIC,2) as avg_price_per_meter_sold
		,ROUND(AVG(avg_total_area_sold))  as avg_total_area_sold
	FROM adv_stats_added as asa
	FULL JOIN adv_stats_sold as ass on   asa.month_added = ass.month_sold
	-- отфильтровываем только те года, по которым есть данные за весь год (2015-2018)
	WHERE 
	ExTRACT(YEAR FROM month_added) BETWEEN 2015 AND 2018
	GROUP BY month_added
	ORDER BY month_added
)
-- Основной запрос - сезонная статистика (по номеру месяца)
SELECT
	month_num
		,SUM(adv_count_added) as adv_count_added
		,ROUND(AVG(avg_price_per_meter_added)::NUMERIC,2) as avg_price_per_meter_added
		,ROUND(AVG(avg_total_area_added)) AS avg_total_area_added
		,SUM(adv_count_sold) as adv_count_sold
		,ROUND(AVG(avg_price_per_meter_sold)::NUMERIC,2) as avg_price_per_meter_sold
		,ROUND(AVG(avg_total_area_sold))  as avg_total_area_sold
FROM year_and_monnth_stats
GROUP BY month_num
ORDER BY month_num;

/*month_num|adv_count_added|avg_price_per_meter_added|avg_total_area_added|adv_count_sold|avg_price_per_meter_sold|avg_total_area_sold|
---------+---------------+-------------------------+--------------------+--------------+------------------------+-------------------+
        1|            976|                 99089.64|                  60|          1217|               104782.16|                 60|
        2|           1914|                 97531.45|                  59|          1019|                95755.19|                 56|
        3|           1553|                 93618.02|                  59|          1234|                93896.20|                 55|
        4|           1303|                 97340.64|                  57|          1094|                92902.55|                 56|
        5|           1106|                 97790.53|                  57|           985|                93666.82|                 55|
        6|           1618|                 97464.54|                  55|          1064|                94334.62|                 57|
        7|           1508|                 96723.96|                  58|          1496|                95800.54|                 56|
        8|           1557|                 95842.27|                  56|          1576|                93984.39|                 55|
        9|           1783|                 98709.02|                  60|          1694|                97184.29|                 55|
       10|           1875|                 97999.23|                  59|          1884|                96432.70|                 57|
       11|           2035|                 96438.72|                  56|          1891|                94485.52|                 56|
       12|           1323|                 97448.85|                  56|          1732|                95458.49|                 57|*/

--:: Выводы.
--:: По подсчётам за 2015-2018 годы активнее всего публикуется и продаётся недвижимость в ноябре месяце.
--:: 
--:: По влиянию сезонности на среднюю цену за квадрат сложно сделать объективный анализ, т.к. цена могла, во-первых, в случайном порядке меняться в течение срока размещения
--:: объявления, во-вторых, при фактическом совершении сделки могла быть в случайном порядке отличной от указанной в имеющихся данных. 
--:: На основе представленных данных можно сказать, что самые дорогие квартиры (ср.цена за квадрат, площадь) выставляются и снимаются с публикации в январе месяце.


-----------------------------------------------------------------
------------------ Задача 3. Анализ рынка недвижимости Ленобласти
/*декомпозируем:
0) объявления, квартиры из Ленобласти (отфильтрованные от аномалий)
00) выбрать необходимые столбцы: id, цена за квадрат, площадь, продолжительность публикации (в т.ч. NULL), нас.пункт, тип нас.пункта
1) посчитать средние значения выбранных данных, сгруппировав их по нас.пункту, выбрать топ 15 нас.пунктов по количеству объявлений
2) подписать к каждому нас. пункту долю снятых объявлений
3) подписать к каждому нас. пункту ср.цену за квадрат
4) подписать к каждому нас. пункту ср. площадь квартиры
5) подписать минимальную продолжительность публикации
6) -//- максимальную
7) -//- среднюю*/

WITH
flats_filtration AS
 (
	 SELECT
		'total_area' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY total_area) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY total_area) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'rooms' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY rooms) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY rooms) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'balcony' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY balcony) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY balcony) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'ceiling_height' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS percentile_01
	FROM  real_estate.flats
	UNION ALL
	SELECT
		'floor' AS flats_data
		, percentile_cont(0.99) WITHIN GROUP (ORDER BY floor) AS percentile_99
		, percentile_cont(0.01) WITHIN GROUP (ORDER BY floor) AS percentile_01
	FROM  real_estate.flats
 )
, flat_ids_lenoblast AS
(
			SELECT 
				id
			FROM real_estate.flats
			WHERE 
		   -- кроме аномально больших площадей 
			  (total_area < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='total_area') OR total_area IS null)     
		   -- кроме аномально больших количеств комнат
			  AND
			  (rooms < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='rooms')  OR rooms IS null)
		   -- кроме аномально больших количеств балконов
			  AND
			  (balcony < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='balcony') OR balcony IS null)
		   -- кроме аномально высоких потолков
			  AND
			  (ceiling_height < (SELECT percentile_99 FROM flats_filtration WHERE flats_data='ceiling_height') OR ceiling_height IS NULL)
		   -- кроме аномально низких потолков (высота менее 2 м кажется нереальной)
			  AND
			  (ceiling_height >= 2 OR ceiling_height IS NULL)
		   -- только квартиры из Ленобласти (идентификатор н.пункта, отличный от идентификатора Санкт-Петербурга)
			  AND 	
			  city_id <> '6X8I'   
)
-- Основной запрос: группируем статистические данные по н.пунктам, отбираем топ-15 по количеству объявлений
SELECT
	c.city 
	,t.TYPE
	,COUNT(a.id) AS adv_count
	,ROUND((count(a.days_exposition)/COUNT(a.id)::numeric)*100,2) AS "sold_%"
	,ROUND(AVG(a.last_price/f.total_area)::NUMERIC,2) AS AVG_price_meter
	,ROUND(AVG(f.total_area)) AS AVG_total_area 
	,MIN(a.days_exposition) AS days_exp_MIN
	,MAX(a.days_exposition) AS days_exp_MAX
	,ROUND(AVG(a.days_exposition)) AS days_exp_AVG
FROM real_estate.flats AS f
JOIN real_estate.advertisement AS a USING(id)
JOIN real_estate.city c USING(city_id)
JOIN real_estate.TYPE t USING(type_id)
WHERE id IN (SELECT id FROM flat_ids_lenoblast)
GROUP BY c.city, t.TYPE
ORDER BY adv_count DESC
LIMIT 15;

/*city           |type   |adv_count|sold_%|avg_price_meter|avg_total_area|days_exp_min|days_exp_max|days_exp_avg|
---------------+-------+---------+------+---------------+--------------+------------+------------+------------+
Мурино         |посёлок|      543| 99.26|       85720.69|          44.0|         3.0|      1187.0|       149.0|
Шушары         |посёлок|      433| 92.61|       78843.42|          53.0|         3.0|      1130.0|       157.0|
Всеволожск     |город  |      388| 85.82|       68557.14|          55.0|         4.0|      1413.0|       198.0|
Пушкин         |город  |      357| 83.47|      102409.46|          57.0|         3.0|      1512.0|       203.0|
Колпино        |город  |      328| 91.46|       75323.83|          51.0|         3.0|      1131.0|       140.0|
Парголово      |посёлок|      326| 92.33|       90332.26|          51.0|         3.0|      1452.0|       156.0|
Гатчина        |город  |      298| 87.25|       68752.97|          50.0|         3.0|       988.0|       187.0|
Кудрово        |деревня|      295|100.00|       92748.92|          46.0|         3.0|      1149.0|       182.0|
Выборг         |город  |      233| 87.55|       58213.30|          56.0|         3.0|      1005.0|       177.0|
Петергоф       |город  |      197| 88.32|       84487.55|          50.0|         7.0|      1273.0|       200.0|
Сестрорецк     |город  |      175| 89.14|      102656.73|          60.0|         5.0|      1489.0|       214.0|
Кудрово        |город  |      173| 82.08|      100253.04|          46.0|         3.0|      1313.0|       116.0|
Красное Село   |город  |      167| 89.22|       72445.19|          51.0|         3.0|      1265.0|       191.0|
Новое Девяткино|деревня|      140| 87.86|       76203.16|          51.0|         3.0|      1580.0|       192.0|
Сертолово      |город  |      138| 84.78|       69467.83|          53.0|         3.0|      1160.0|       191.0|*/

--:: Выводы.
--:: 
--:: Наиболее активно публикуют объявления в посёлках Мурино и Шушары.
--:: 
--:: Топ-3 н.п. по самой высокой доле снятых с публикации объявлений это Кудрово (100%), Мурино (99,2%), Шушары (92,6%)
--:: 
--:: Разброс средней цены за квадрат почти двухкратный- 58-102тыс. Разброс средней площади 44-60 квадратов, и минимальная средняя площадь
--:: приходится на топовый н.п. по активности (Мурино)
--:: 
--:: Быстрее всего снимаются объявления в городах Кудрово, Колпино и посёлке Мурино.
--:: Медленнее всего в Сестрорецке, Пушкине и Петергофе.
--:: Почти во всех топ-15 н.п. по активности объявлений минимальный порог длительности публикации 3 дня, на меньшее вряд ли можно рассчитывать.






-- CHECK TABLE FILEDS
SELECT 
    *
FROM tattoo_studio
LIMIT 10
;

-- UNIQUE CUSTOMERS
SELECT 
    COUNT(DISTINCT mobile_number)
FROM tattoo_studio
;


-- MIN AND MAX DATES
SELECT 
    MIN(appointment_date), 
    MAX(appointment_date)
FROM tattoo_studio
;


-- MIN AND MAX AGES
SELECT 
    MIN(age), 
    MAX(age)
FROM tattoo_studio
;

-- % OF TOTAL BY AGE SEGMENTS
SELECT
	segmento,
	COUNT(*) as total,
	ROUND(COUNT(*) / (SELECT COUNT(*) FROM tattoo_studio) * 100,2) AS "%_total"
FROM	
	(SELECT
		age,
		CASE
			WHEN age >= 18 AND age < 25 THEN "segment 1 - 18-24"
			WHEN age >= 25 AND age < 31 THEN "segment 2 - 25-30"
			WHEN age >= 31 AND age < 41 THEN "segment 3 - 31-40"
			WHEN age >= 41 AND age < 48 THEN "segment 4 - 41-47"
			ELSE "segment 5 - 48-55+"
		END AS "segmento"
	FROM tattoo_studio) AS a
GROUP BY 1
ORDER BY 3 DESC;


-- % OF TOTAL BY GENDER
SELECT
	gender,
    COUNT(*) AS total,
	ROUND(COUNT(*)  / (SELECT COUNT(*) FROM tattoo_studio) * 100,2) AS "%_total"
FROM tattoo_studio
GROUP BY 1
ORDER BY 3 DESC
;

-- % OF TOTAL BY STYLE
SELECT
	tattoo_style,
    COUNT(*) AS total,
	ROUND(COUNT(*)  / (SELECT COUNT(*) FROM tattoo_studio) * 100,2) AS "%_total"
FROM tattoo_studio
GROUP BY 1
ORDER BY 3 DESC
;

-- % OF TOTAL BY SESSION TYPE
SELECT
	Session_type,
    COUNT(*) AS total,
	ROUND(COUNT(*)  / (SELECT COUNT(*) FROM tattoo_studio) * 100,2) AS "%_total"
FROM tattoo_studio
GROUP BY 1
ORDER BY 3 DESC
;

-- % OF TOTAL BY ARTIST
SELECT
	artist_name,
    COUNT(*) AS total,
	ROUND(COUNT(*)  / (SELECT COUNT(*) FROM tattoo_studio) * 100,2) AS "%_total"
FROM tattoo_studio
GROUP BY 1
ORDER BY 3 DESC
;
;

-- % OF TOTAL - BILLING BY ARTIST
SELECT
	artist_name,
    SUM(final_rate_usd) AS total,
    ROUND(SUM(Final_Rate_USD) / (SELECT SUM(Final_Rate_USD) FROM tattoo_studio) *100,2) AS "%_total"
FROM tattoo_studio
GROUP BY 1
ORDER BY 3 DESC
;

-- AVERAGE SATISFACTION RATE BY ARTIST
SELECT
	artist_name,
    ROUND(AVG(customer_satisfaction),2) AS "avg_customer_satisfaction"
FROM tattoo_studio
GROUP BY 1
ORDER BY 2 DESC
;


-- MOST REVENUE BY TATTOO STYLE BY HOUR
WITH tabla_horas AS (
	SELECT
		mobile_number,
        age,
        gender,
        appointment_date,
        session_type,
        tattoo_size,
        tattoo_style,
        artist_name,
        session_hours,
        final_rate_usd,
        final_rate_usd / session_hours AS "total_x_hour"
	FROM tattoo_studio
)
SELECT
	tattoo_style,
    COUNT(tattoo_style) AS conteo_total,
	ROUND(AVG(total_x_hour),2) AS avg_x_hora,
	ROUND(SUM(final_rate_usd),2) AS total_x_style
FROM tabla_horas
GROUP BY 1
ORDER BY 4 DESC
;


-- TOTAL REVENUE, AVERAGE PER HOUR, AVERAGE RATE AND TOTAL AMMOUNT BY SESSION TYPE AND TATTOO STYLE
SELECT
	session_type,
    tattoo_style,
    COUNT(tattoo_style) AS total_count,
    ROUND(AVG(final_rate_usd),2) AS avg_rate,
    ROUND(AVG(final_rate_usd / session_hours),2) AS "avg_x_hour",
    ROUN(SUM(final_rate_usd),2) AS totaal
FROM tattoo_studio
GROUP BY 1,2
ORDER BY 1,3 DESC
;







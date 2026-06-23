# Case Study: Boosting Efficiency and Market Analysis in the Tattoo Industry
**Role:** Data Analyst & Business Consultant  
**Tech Stack:** Python (Pandas), SQL (MySQL), Power BI, DAX  

---

## 1. Background & Business Problem

### The Big Picture (Macro View)
The global tattoo industry is booming like never before. According to reports from *Fortune Business Insights*, the global market was worth **$2.43 billion USD back in 2023** and is expected to hit **$4.86 billion USD by 2032**. That’s a steady 8.0% annual growth rate (CAGR). An industry that’s literally going to double its size in a decade can’t be run on "gut feelings" anymore—it needs data-driven decisions.

On top of that, macro data shows that **72.5% of global revenue** is packed into North America and Europe. In these mature, high-traffic markets, the hourly cost of keeping a shop chair running is the ultimate make-or-break metric.

### The Local Reality (Micro View)
A high-performing tattoo studio located in a busy, high-foot-traffic commercial area is bringing in good money, but it has some hidden operational leaks:

* **Guesswork in Chair Profitability:** The management doesn't really know which tattoo styles make the most money per hour. This leads to messy scheduling and wasted money on marketing campaigns that target the wrong styles.
* **The Walk-in Price Trap:** The shop handles two types of clients: scheduled appointments (`Pre-booked`) and spontaneous, off-the-street clients (`Walk-in`). Right now, they both pay the exact same rates. From a business standpoint, this is a massive missed opportunity. The shop is failing to charge a "convenience fee" that takes advantage of high foot traffic and impulse buys.

### Project Goals
* **Goal 1:** Build an automated pipeline to clean up and migrate the shop's entire operational history.
* **Goal 2:** Pinpoint which tattoo styles bring in the highest cash flow per hour to maximize schedule efficiency.
* **Goal 3:** Measure the actual income gap between *Pre-booked* appointments and *Walk-ins* to design a smarter pricing strategy.
* **Goal 4:** Double-check if the shop's customer demographics match the macro trends of the market (where the 18-35 age group makes up over 55% of the total demand).


## 2. Data Cleaning & Ingestion Pipeline (Python)

The original dataset was sitting in a `.csv` file, with prices listed in Rupees and plenty of null values in the extra services column. To fix this, I built a **Python (Pandas)** script to standardize all financial metrics into US Dollars (USD), fix the date formats, and pipe the clean table straight into a local **MySQL** database.
```python
#Import Libraries
import pandas as pd
from sqlalchemy import create_engine

#Load file .csv
df = pd.read_csv("tattoo_studio_dataset.csv")

# Convert to USD$ Final_Rate y Total_Bill
df.loc[:,"Final_Rate_USD"] = df["Final_Rate"] / 94.5
df.loc[:,"Total_Bill_USD"] = df["Total_Bill"] / 94.5 

# Remove Rupies Columns
df = df.drop("Final_Rate", axis = 1)
df = df.drop("Total_Bill", axis = 1)

# Asiggn Date Format to "Appointment_Date"
df["Appointment_Date"] = pd.to_datetime(df["Appointment_Date"], format = '%Y-%m-%d')

# Replace Nulls (NaN) in "Additional_Services"
df['Additional_Services'] = df['Additional_Services'].fillna("None")

# EXPORT
# 1. Define parameters
USER = "" # user name here
PASSWORD = ""  # password here
HOST = "" # host here
PORT = "" # port here
DATABASE = "tattoo_db"  

# 2. Create conection (Engine)
engine = create_engine(f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}")

# 3. Export DataFrame
df.to_sql(
    name="tattoo_studio",  
    con=engine,
    if_exists="replace",
    index=False,
)

print("Dataset Exported")
```


## 3. Advanced Exploratory Data Analysis (SQL)

Once the data was structured inside the relational database, I ran advanced queries using Common Table Expressions (CTEs) and aggregate functions to break down the two most critical variables of the business.

### Query 1: Performance and Revenue by Tattoo Style
```sql
WITH tabla_horas AS ( 
	SELECT 
		tattoo_style, 
		session_hours, 
		final_rate_usd, 
		(final_rate_usd / session_hours) AS total_x_hour 
	FROM tattoo_studio ) 
SELECT 
	tattoo_style, 
	COUNT(tattoo_style) AS total_unidades, 
	ROUND(AVG(total_x_hour), 2) AS avg_por_hora, 
	ROUND(SUM(final_rate_usd), 2) AS total_facturacion 
FROM tabla_horas 
GROUP BY 1 
ORDER BY 3 DESC;
```

### Query 2: Cross-Section Analysis: Session Type vs. Tattoo Style
```sql
SELECT
    session_type,
    tattoo_style,
    COUNT(tattoo_style) AS cantidad_citas,
    ROUND(AVG(final_rate_usd), 2) AS ticket_promedio,
    ROUND(SUM(final_rate_usd), 2) AS total_facturado
FROM tatuajes_limpio
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

### Query 3: Market Share Percentage by Customer Age Groups
```sql
SELECT
segmento,
COUNT(*) AS total,
ROUND(COUNT(*) / (SELECT COUNT(*) FROM tattoo_studio) * 100,2)  AS "%_total"
FROM	
	(SELECT
		age,
		CASE
			WHEN age >= 18 AND age < 25 THEN "segment 1 - 18-24"
			WHEN age >= 25 AND age < 31 THEN "segment 2 - 25-30"
			WHEN age >= 31 AND age < 41 THEN "segment 3 - 31-40"
			WHEN age >= 41 AND age < 48 THEN "segment 4 - 41-47"
			ELSE "segment 5 - 48-55+"
		end AS "segment"
	FROM tattoo_studio) AS a
GROUP BY 1
ORDER BY 3 DESC;
```


## 4. Key Findings (Business Insights)

After cross-referencing the query results with the demographic breakdown, I pulled four high-impact conclusions from the data:

* **The Walk-in Pricing Trap:** The data shows that both the average ticket and the hourly rate for *Walk-in* clients are pretty much identical to scheduled appointments (*Pre-booked*). In a high-foot-traffic area, this means the studio is basically subsidizing the customer's urgency and impulse behavior. The business is missing out on a huge opportunity to grab higher profit margins through a "convenience fee."

* **The "Golden Chairs" (Realism vs. Custom):** **Realism** is the most efficient style in the shop, leading the pack with the highest hourly rate at **$140.07 USD/hour**. On the flip side, **Custom** tattoos dominate absolute demand volume (435 services—making up 21.75% of the total) and total revenue ($120,387 USD). Together, these two styles are the main economic engines of the studio.

* **The Steady Cash Flow Baseline:** Even though *Tribal* and *Minimalist* styles sit at the lower end of the metrics, their volume and ticket sizes stay remarkably close to the top performers. They aren't a drag on operations at all; instead, they provide a rock-solid, predictable baseline of daily cash flow that keeps the business stable.

* **A Mature Crowd with Higher Buying Power:** Unlike general macro trends where younger crowds (18-30 years old) drive the market, the data shows our sweet spot is actually **clients aged 31 and up, with a major concentration in the 31-40 bracket**. While a more mature audience might mean fewer impulse buys, from a business perspective it's an incredible advantage: they have higher job stability, better income, and significantly more spending power. This means more decisive clients who choose larger, more complex, and highly detailed pieces, driving up the net profit margin per session.


## 5. Visualization & Strategic Recommendations

I designed an interactive, executive-level dashboard in Power BI, connecting it directly to the MySQL database. Key metrics were modeled using custom DAX formulas—such as dynamic average ticket calculations and age bracket segmentation using the `SWITCH(TRUE())` logic.

### Consulting Recommendations for Management:

*   **Implement Premium Pricing for Walk-ins:** Restructure the pricing model to introduce a strategic **10% to 15% hourly markup** on all *Walk-in* services. This should be prioritized for high-demand styles (*Custom*, *Script*, and *Realism*) to fully monetize the heavy foot traffic in the area.

*   **Price Adjustments Based on Specialization:** Raise the base rate for scheduled (*Pre-booked*) appointments in *Realism* and *Custom* styles. Since these styles require high-level artistic skill and customers already show a strong willingness to pay, the studio can easily absorb a margin increase without hurting booking volumes.

*   **Targeted High-Volume Marketing:** Direct a portion of the digital ad budget toward capturing the 18-30 age group—the demographic identified by the dashboard as the highest in overall volume—by showcasing *Realism* pieces to fill any open gaps in the studio's schedule.

*   **High-Conversion Marketing Strategy for Mature Clients:** Design and run digital marketing campaigns specifically tailored to the **31-40 age bracket**. Unlike traditional industry ads that focus on rebellion or fast-moving youth trends, social media content for this group should be mature, sophisticated, and professional. The focus should shift to artist experience, strict biosecurity standards, the artistic value of large-scale pieces, and service exclusivity. This will speed up customer acquisition for the studio's most profitable, highest Lifetime Value (LTV) segment.

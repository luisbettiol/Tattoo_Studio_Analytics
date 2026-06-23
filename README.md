# Caso de Estudio: Optimización Operativa y Análisis de Mercado en la Industria del Tatuaje
**Rol:** Analista de Datos y Consultor de Negocio  
**Tecnologías:** Python (Pandas), SQL (MySQL), Power BI, DAX  

---

## 1. Contexto y Problema de Negocio

### El Panorama Macro
La industria global del tatuaje se encuentra en una fase de expansión sin precedentes. Basado en los reportes de *Fortune Business Insights*, el tamaño del mercado global se valoró en **$2.43 billones de USD en 2023** y se proyecta que alcance los **$4.86 billones de USD para 2032**, lo que representa una tasa de crecimiento anual compuesta (CAGR) del 8.0%. Una industria que prácticamente duplicará su valor en una década exige una transición de la gestión informal hacia decisiones respaldadas por datos. 

Además, la analítica macro revela que el **72.5% de la facturación global** se concentra en Norteamérica y Europa, mercados maduros y de alto tráfico donde el costo operativo por hora de silla es el KPI crítico de supervivencia.

### La Problemática Micro
Un estudio de tatuajes de alto rendimiento, ubicado en una zona comercial de alta densidad peatonal, presenta un crecimiento en la facturación pero con ineficiencias operativas ocultas:
1. **Incertidumbre en la Rentabilidad de la Silla:** Se desconoce qué estilos de tatuaje optimizan mejor el ingreso por hora trabajada, lo que provoca una asignación ineficiente de la agenda y de las campañas de marketing.
2. **Paridad Ineficiente en Walk-ins:** El estudio maneja dos modalidades de atención: citas programadas (`Pre-booked`) y clientes espontáneos (`Walk-in`). Actualmente, ambos segmentos comparten la misma estructura tarifaria. Administrativamente, esto representa una oportunidad perdida de capturar valor a través de una "tarifa de conveniencia" que capitalice el alto tráfico y la compra por impulso.

### Objetivos del Proyecto
* **Objetivo 1:** Construir un pipeline automatizado para limpiar y migrar el histórico de operaciones del estudio.
* **Objetivo 2:** Identificar los estilos de tatuaje con mayor retorno financiero por hora para maximizar la capacidad de la agenda.
* **Objetivo 3:** Evaluar la brecha de ingresos entre *Pre-booked* y *Walk-ins* para diseñar una nueva estrategia de precios.
* **Objetivo 4:** Validar si el comportamiento demográfico del estudio se alinea con la tendencia macro del mercado (donde el grupo de 18-35 años abarca más del 55% de la demanda).

---

## 2. Pipeline de Limpieza e Ingesta de Datos (Python)

El dataset operativo original se encontraba en formato `.csv` con montos expresados en rupias y registros de servicios adicionales con valores nulos. Se construyó un script en **Python (Pandas)** para estandarizar las métricas a dólares americanos (USD), corregir tipos de datos temporales y exportar de forma directa la tabla limpia hacia un servidor local de **MySQL**.

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

---

## 3. Análisis Exploratorio Avanzado (SQL)

Con los datos estructurados en la base de datos relacional, se ejecutaron consultas avanzadas utilizando **Common Table Expressions (CTEs)** y funciones de agregación para desglosar las dos variables críticas del negocio.

### Consulta 1: Rendimiento y Facturación por Estilo de Tatuaje
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

### Consulta 2: Intersección entre Modalidad de Sesión y Estilo
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

### Consulta 3: Porcentaje de Participación por Segmentos de Clientela por Rango de Edad 
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

---

## 4. Hallazgos Clave (Insights de Negocio)

Tras cruzar los resultados de las consultas y la segmentación demográfica, se extrajeron tres conclusiones analíticas de alto impacto:

1. **La Paridad Ociosa del Walk-in:** Los datos demuestran que el ticket promedio y el valor por hora de los clientes _Walk-in_ son prácticamente idénticos a los de las citas programadas (_Pre-booked_). En un entorno de alto tráfico peatonal, esto confirma que el estudio está subsidiando la urgencia/impulsividad del cliente, perdiendo la oportunidad de capturar un margen de ganancia más alto por tarifa de conveniencia.

2. **La Silla de Oro (Realismo vs. Personalizado):** El estilo **Realism** lidera la eficiencia del estudio con la tarifa por hora más alta del negocio (**$140.07 USD/hora**). Por otro lado, el estilo **Custom** domina el volumen absoluto de demanda (435 servicios - 21.75% del Total) y la facturación total ($120,387 USD). Juntos, representan los motores económicos del local.

3. **Estabilidad del Catálogo Fijo:** Los estilos _Tribal_ y _Minimalist_, aunque se ubican en el escalón inferior de las métricas, mantienen volúmenes y tickets sumamente cercanos a los líderes. No representan un lastre operativo, sino una base sólida y constante de flujo de caja que estabiliza el negocio.

4. **Madurez Demográfica y Poder Adquisitivo Elevado:** A diferencia de las tendencias macro generales del sector —donde el núcleo de la demanda suele concentrarse en audiencias más jóvenes (18-30 años), los datos de este estudio revelan que el segmento de clientes más fuerte pertenece a los **31 años en adelante, con especial dominancia en el rango de 31-40 años**. Si bien una audiencia más madura puede reducir el factor de "impulsividad" en la compra, administrativamente representa una enorme ventaja competitiva: es un público con mayor estabilidad laboral, ingresos más altos y, por ende, un **poder adquisitivo significativamente superior**. Esto se traduce en clientes más decididos que optan por piezas más grandes, complejas y elaboradas, inyectando un mayor margen de beneficio neto por sesión en el estudio.

---

## 5. Visualización y Recomendaciones Estratégicas

Se diseñó un Dashboard ejecutivo e interactivo en **Power BI**, conectando de forma directa la tabla de MySQL y modelando métricas clave mediante **DAX** (como el cálculo dinámico del ticket promedio y la segmentación de clientes por rangos de edad mediante `SWITCH(TRUE())`).

### Recomendaciones de Consultoría para la Gerencia:
- **Implementación de Tarifa Premium para Walk-ins:** Reestructurar los precios e introducir un recargo estratégico del **10% al 15% por hora** en los servicios _Walk-in_, aplicando esta medida con prioridad en los estilos de alta demanda (Custom, Script y Realism) para monetizar de forma óptima el tráfico peatonal de la zona.

- **Ajuste de Precios por Especialización:** Elevar la tarifa base de las citas programadas para _Realism_ y _Custom_. Al ser estilos que requieren alta destreza y presentan la mayor disposición de pago por parte del cliente, el estudio puede absorber un incremento de margen sin afectar significativamente el volumen de reservas.

- **Campañas de Marketing Segmentadas:** Dirigir el presupuesto publicitario digital a captar clientes de entre 18 y 30 años (el segmento demográfico que el Dashboard identificó como el de mayor volumen), promocionando piezas de _Realismo_ para optimizar las horas disponibles de las sillas del estudio.

- **Estrategia de Marketing de Alta Conversión para Clientes Maduros:** Diseñar y ejecutar campañas de marketing digital específicamente segmentadas para el público de 31 a 40 años. A diferencia de la publicidad tradicional del sector, enfocada en la rebeldía o las tendencias pasajeras de la audiencia joven, el contenido en redes sociales debe adoptar un tono más maduro, sofisticado y profesional. Se debe hacer énfasis en la experiencia de los artistas, las condiciones de bioseguridad, el valor artístico de las piezas grandes y la exclusividad del servicio. Esto permitirá acelerar la adquisición del perfil de cliente más rentable y con mayor valor de vida (Lifetime Value) para el estudio.
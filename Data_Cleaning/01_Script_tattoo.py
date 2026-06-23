#Importar Librerias
import pandas as pd 
from sqlalchemy import create_engine

#Cargar archivo .csv
df = pd.read_csv("tattoo_studio_dataset.csv")

# Convertir los montos a USD$
# Asignar formato de fecha a "Appointment_Date"
# Imputar Nulos (NaN) de "Additional_Services"

# Convertir los montos a USD$ en Final_Rate y Total_Bill
df.loc[:,"Final_Rate_USD"] = df["Final_Rate"] / 94.5
df.loc[:,"Total_Bill_USD"] = df["Total_Bill"] / 94.5

# Remover columnas con montos en rupias
df = df.drop("Final_Rate", axis = 1)
df = df.drop("Total_Bill", axis = 1)

# Asignar formato de fecha a "Appointment_Date"
df["Appointment_Date"] = pd.to_datetime(df["Appointment_Date"], format = '%Y-%m-%d')

# Imputar Nulos (NaN) de "Additional_Services"
df['Additional_Services'] = df['Additional_Services'].fillna("None")

# EXPORT
# 1. Definir los parámetros de conexion
USER = "root"
PASSWORD = "401404"  
HOST = "localhost"
PORT = "3306"
DATABASE = "tattoo_db"  

# 2. Crear el motor de conexión (Engine)
engine = create_engine(f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}")

# 3. Exportar el DataFrame 
df.to_sql(
    name="tattoo_studio",  
    con=engine,
    if_exists="replace", 
    index=False,
)

print("Dataset Exportado")
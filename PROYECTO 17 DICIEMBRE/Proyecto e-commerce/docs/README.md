##### Proyecto RA1 - ECOMMERCE ####

## Descripción del proyecto 

El objetvo en este proyecto trata sobre limpiar un dataset de un e-commerce con dos librerias distintas, de manera que podemos valorar las ventanjas y las desventajas de ambas, como Pandas (que es más tradicional y fácil de usar) y PySpark (que es más potente y escalable). Al final, ambos métodos se cargan los datos en SQLite con un modelo de tablas.

El dataset original tiene unas 10.000 lineas/pedidos con los campos (clientes, productos, detalles de compra, informacion de pago, envio, estado, fecha), donde encuentras varios errores, sobretodo numericos, como valores vacios, valores nulos o formatos incorrectos.

Al limpiar todo el dataset y hacerlo con Pandas y PySpark, puedes ver en que campos son más utiles las dos librerias.


## Explicación de cada fase 


# Fase 1: Exploración y limpieza con Pandas (01_pandas.ipynb)

Esta es la fase más importante porque es donde vemos todos los problemas del dataset.

Lo primero que vemos es como se cargan las librerías básicas (Pandas, NumPy, SQLite3) y importar el archivo CSV. Una vez cargado, hacemos un análisis completo del dataset. Revisamos las dimensiones (10,000 registros por 15 columnas), sacamos los tipos de datos de cada column.


0   order_id        9893 non-null   float64
1   customer_id     10000 non-null  int64  
2   customer_name   10000 non-null  object 
3   product_id      10000 non-null  int64  
4   product_name    10000 non-null  object 
5   category        10000 non-null  object 
6   order_date      10000 non-null  object 
7   quantity        9908 non-null   float64
8   unit_price      10000 non-null  object 
9   total_price     9002 non-null   float64
10  payment_method  10000 non-null  object 
11  country         10000 non-null  object 
12  city            10000 non-null  object 
13  status          10000 non-null  object 
14  update_time     10000 non-null  object 



Luego identificamos los problemas: encontramos valores en blanco en la columna total_price, en quantity, en fechas con los formatos, precios con comas , categorías con  mayúsculas y minúsculas, y nombres de países desordenados.


# Fase 2: Procesamiento con PySpark (02_pyspark.ipynb)
En esta fase demostramos que podemos procesar los mismos datos con PySpark aunque se suela utilizar para grandes cantidades de datos.

Importamos todas las librerias necesarias que vamos a usar en spark.

import pyspark
from pyspark.sql import SparkSession, Row
from pyspark.sql.functions import col, sum, avg, count, desc, round, row_number, max as spark_max, when, isnan, lit
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType
from pyspark.sql.window import Window
import time
import sqlite3 (esta la añadiremos más tarde en la Fase 4)

Creamos una SparkSession (la "conexión" de Spark) y cargamos el mismo CSV.

✓ Dataset cargado: 10,000 registros
root
 |-- order_id: double (nullable = true)
 |-- customer_id: integer (nullable = true)
 |-- customer_name: string (nullable = true)
 |-- product_id: integer (nullable = true)
 |-- product_name: string (nullable = true)
 |-- category: string (nullable = true)
 |-- order_date: string (nullable = true)
 |-- quantity: double (nullable = true)
 |-- unit_price: string (nullable = true)
 |-- total_price: double (nullable = true)
 |-- payment_method: string (nullable = true)
 |-- country: string (nullable = true)
 |-- city: string (nullable = true)
 |-- status: string (nullable = true)
 |-- update_time: timestamp (nullable = true)



# Fase 3: Proceso ETL con Pandas

Para conseguir el ETL: 

La lectura del archivo o extracción la hacemos en la Fase 1

Para solucionar la Transformaciónn, convertimos todas las fechas a un formato estándar (YYYY-MM-DD) usando pd.to_datetime(), limpiamos los precios reemplazando comas por puntos y convirtiéndolos a float, rellenamos los valores faltantes de total_price calculando cantidad × precio_unitario, normalizamos todas las categorías a mayúsculas y arreglamos los paises con dos letras en vez del nombre completo.

df.info()
print(f"Valores faltantes: {df.isnull().sum().sum()}") 
print(df.head())

- Conseguimos 0 valores nulos


Creamos tres tablas:

dim_clientes: Contiene información única de cada cliente (customer_id y customer_name). 

dim_productos: Almacena el catálogo de productos con su nombre y categoría. istros únicos. Esta tabla sirve como referencia de qué productos existen.

fact_pedidos: Es la tabla central que contiene todas las 10,000 transacciones. 




# Fase 4: Proceso ETL con PySpark

Esta fase es prácticamente igual a la Fase 3, pero usando datos procesados por PySpark en lugar de Pandas. 

Una vez cargado, realizamos los pasos necesarios para limpiar el dataset y añadimos nuevas columnas/filtros.

df = df.withColumn(
    "precio_sin_iva",
    round(col("total_price") / 1.21, 2)
)


df_top10 = df.orderBy(desc("total_price")).limit(10)

print("Top 10 órdenes más caras:\n")
df_top10.show()



nueva_venta = spark.createDataFrame([
    Row(
        order_id=10001,
        customer_id=2000,
        customer_name="Roberto Martín",
        product_id=201,
        product_name="iPad Pro",
        category="Tecnología",
        order_date="2025-12-12",
        quantity=1,
        unit_price=1299.99,
        total_price=1299.99,
        payment_method="Tarjeta",
        country="Spain",
        city="Madrid",
        status="Pendiente",
        update_time="2025-12-12 01:26:00"
    )
])

Creamos las mismas tres tablas (dim_clientes, dim_productos, fact_pedidos). La diferencia es que convertimos los DataFrames de Spark a Pandas (toPandas()) antes de cargarlos en SQLite, porque SQLite en Python funciona mejor con Pandas.

dim_clientes = dim_clientes_spark.toPandas()
dim_productos = dim_productos_spark.toPandas()
fact_pedidos = fact_pedidos_spark.toPandas()

dim_clientes.to_sql("dim_clientes", conn, if_exists="replace", index=False)
dim_productos.to_sql("dim_productos", conn, if_exists="replace", index=False)
fact_pedidos.to_sql("fact_pedidos", conn, if_exists="replace", index=False)

Guardamos todo en warehouse_pyspark.db. Ahora tenemos dos bases de datos idénticas: una creada por el pipeline Pandas y otra creada por el pipeline PySpark.


# Fase 5: Modelo de Data Warehouse

- Importaremos la libreria Os

- Crear carpeta warehouse
os.makedirs("warehouse", exist_ok=True)

- Creamos las tablas con las claves primarias y las claves foraneas 

- Tabla Clientes

sql_content = """ 
CREATE TABLE dim_clientes (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL
);

- Tabla Productos

CREATE TABLE dim_productos (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL
);

- Tabla Pedidos

CREATE TABLE fact_pedidos (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product_id INTEGER,
    order_date DATE,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    payment_method VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(50),
    update_time TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES dim_clientes(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_productos(product_id)
);
"""
- Creamos los arhivos SQL con el mismo contenido, pero se procesan de distinta forma en Pandas y en Spark

with open("warehouse/modelo_datawarehouse_pandas.sql", "w") as f:
    f.write(sql_content)
    
with open("warehouse/modelo_datawarehouse_pyspark.sql", "w") as f:
    f.write(sql_content)

# Fase 6: Docker 

- Se explica más abajo los pasos para ejecutar los notebooks con Docker.




## Herramientas Utilizadas

- Pandas 2.0.3 
- NumPy 1.24.4 
- PySpark 
- SQLite 
- Jupyter Notebook 
- Python 3.11.6
- Libreria os
- Libreria time



## Estructura de Carpetas


proyecto e-coomerce/
    docker/
        data/
            ecommerce_orders.csv
        notebooks/
            01_pandas.ipynb
            02_pyspark.ipynb
            Creacion de SQL.ipynb
            modelo_datawarehouse_pandas.sql
            modelo_datawarehouse_pyspark.sql
            warehouse/
                warehouse_pandas.db
                warehouse_pyspark.db
        Dockerfile
        docker-compose.yml
        .gitignore
        scripts/
    docs/
        README.md

## Como ejecutar el proyecto

# Sin Docker

1. Instalar dependencias:

- pip install pandas numpy pyspark jupyter

2. Ejecutar Jupyter:

- jupyter notebook

3. Ejecutar los notebooks
   - `01_pandas.ipynb` 
   - `02_pyspark.ipynb` 

# Con Docker

- docker-compose up --build

- Luego acceder a `http://localhost:8888`



## Explicación breve de cada ETL 

# Pandas
- Extracción (E)

df = pd.read_csv('ecommerce_orders.csv')

- Transformación (T) 

Limpieza de fechas con formato o orden invalido al que se usa normalmente

Normalización de categorías y países (corregir mayusculas y dar formato a "paises")

Tratamiento de valores nulos substituyendolos por 0 en los valores numericos y corrigiendo los IDs segun el orden (Ejemplo: 1501, vacio, 1503 (el valor seria 1502))


- Carga (L) 

Crear tabla de clientes: Selecciona customer_id y customer_name, elimina duplicados con dropDuplicates()

Crear tabla de productos: Selecciona product_id, product_name y category, elimina duplicados


conn = sqlite3.connect('warehouse/warehouse_pandas.db')
df.to_sql('fact_pedidos', conn, if_exists='replace', index=False)


# PySpark
- Extracción (E)

spark = SparkSession.builder.appName("ecommerce_warehouse").getOrCreate()
df = spark.read.csv("ecommerce_orders.csv", header=True, inferSchema=True)

- Transformación (T) 


Tratamiento de valores nulos substituyendolos por 0 en los valores numericos y cambiar los formatos de los datos. (Mismo paso que Spark)

Añadir columna extra de precio_sin_iva dividiendo total_price entre 1.21 (elimina IVA del 21%)

Añadir columna nueva al dataset en cuanto a un nuevo pedido (nuevo numero de pedido, cliente, pais, producto, etc...)

Filtrar/Query del top 10 de los productos más vendidos


- Carga (L) 

Crear tabla de clientes: Selecciona customer_id y customer_name, elimina duplicados con dropDuplicates()

Crear tabla de productos: Selecciona product_id, product_name y category, elimina duplicados


conn = sqlite3.connect("warehouse_pyspark.db")
dim_clientes.toPandas().to_sql("dim_clientes", conn, if_exists="replace", index=False)
dim_productos.toPandas().to_sql("dim_productos", conn, if_exists="replace", index=False)
spark.stop()




## Carga de Datos en SQLite

1. Crear las tablas con SQL
2. Extraer las tablas 
3. Cargar con to_sql() de Pandas
4. Validar que los datos estan en las tablas y la creacion

Los archivos SQL contienen:
- **dim_clientes**: 1 tabla de dimensión
- **dim_productos**: 1 tabla de dimensión  
- **fact_pedidos**: 1 tabla de hechos

- Cada base de datos (pandas y pyspark) contiene las mismas 3 tablas pero procesadas de distinta forma.

## Modelo Dimensional

Tabla: dim_clientes    |  Tabla: dim_productos          |  Tabla: fact_pedidos
- customer_id (PK)     |  - product_id (PK)             |  - order_id (PRIMARY KEY)
- customer_name        |  - product_name                |  - customer_id (FK → dim_clientes)
                       |  - category                    |  - product_id (FK → dim_productos)
                       |                                |  - order_date
                       |                                |  - quantity
                       |                                |  - unit_price
                       |                                |  - total_price
                       |                                |  - payment_method
                       |                                |  - country
                       |                                |  - city
                       |                                |  - status
                       |                                |  - update_time

 ______________
| dim_clientes |
|______________|
      |
      |_______________
      |               |
  ____|_____     _____|_________
 |dim_prod  |   | fact_pedidos  |
 |__________|   |_______________|
      |              |
      |______________| 
       Relaciones FK
                                        
# DDL de las Tablas (SQLite)         


- Dimensión Clientes:
```sql
CREATE TABLE dim_clientes (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL
);
```

- Dimensión Productos
```sql
CREATE TABLE dim_productos (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL
);
```

- Tabla de Hechos:
```sql
CREATE TABLE fact_pedidos (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product_id INTEGER,
    order_date DATE,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    payment_method VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(50),
    update_time TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES dim_clientes(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_productos(product_id)
);
```






## Consultas, y queries que se pueden realizar 

# Dos consultas de prueba para ver las tablas

- Muestra las tablas de la BBDD

```sql
SELECT name FROM sqlite_master WHERE type='table'
    
- Muestra la tabla pedidos

SELECT * FROM fact_pedidos

```
# Consultas y queries mas elaboradas (no se encuentran dentro de los archivos)

- ¿Cuales son los clientes con mas compras?

```sql
SELECT 
    c.customer_name,
    COUNT(f.order_id) as ordenes,
    SUM(f.total_price) as total
FROM fact_pedidos f
JOIN dim_clientes c ON f.customer_id = c.customer_id
GROUP BY f.customer_id
ORDER BY total DESC
```

- Filtrar los pedidos por el pais de destino
```sql
SELECT 
    country,
    COUNT(*) as ordenes,
    SUM(total_price) as total
FROM fact_pedidos
GROUP BY country
ORDER BY total DESC
LIMIT 15;
```

- Cual es el producto mas vendido?

```sql
SELECT 
    p.product_name,
    COUNT(f.order_id) as veces_vendido,
    SUM(f.quantity) as unidades
FROM fact_pedidos f
JOIN dim_productos p ON f.product_id = p.product_id
GROUP BY f.product_id
ORDER BY unidades DESC;
```





## Conclusiones

- Los datasets reales siempre tienen errores. Aquí había fechas en 3 formatos diferentes, precios con comas, mayúsculas, de manera que si no pasan por un filtro, son muy dificiles de utilizar en un entorno real.

- Si dejas algun dato incorrecto, puede afectar toda la base de datos, por ejemplo el precio unitario ya afecta a otras columnas, como precio total, precio sin iva, etc.

- Pandas se suele utilizar y es mas eficiente para datasets pequeños/medianos 

- PySpark es necesario cuando escalas a datos grandes, por ejemplo en este caso no seria tan util con solo 10.000 filas

- Se pueden complementar las dos tipos de liberias, no quiere decir que porque utilizes Spark no puedes usar Pandas.

- Las base de datos ayudan en base a las consultas a saber los datos que hay en el dataset, por ejemplo, los productos con 0 stock para pedir más o los productos más vendidos, etc

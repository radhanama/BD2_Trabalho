
### Primeira Consulta:
```sql
SELECT SUPP_NATION,
	CUST_NATION,
	L_YEAR,
	SUM(VOLUME) AS REVENUE
FROM (
		SELECT N1.N_NAME AS SUPP_NATION,
			N2.N_NAME AS CUST_NATION,
			EXTRACT(
				YEAR
				FROM L_SHIPDATE
			) AS L_YEAR,
			L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS VOLUME
		FROM SUPPLIER,
			LINEITEM,
			ORDERS,
			CUSTOMER,
			NATION N1,
			NATION N2
		WHERE S_SUPPKEY = L_SUPPKEY
			AND O_ORDERKEY = L_ORDERKEY
			AND C_CUSTKEY = O_CUSTKEY
			AND S_NATIONKEY = N1.N_NATIONKEY
			AND C_NATIONKEY = N2.N_NATIONKEY
			AND (
				(
					N1.N_NAME = 'FRANCE'
					AND N2.N_NAME = 'GERMANY'
				)
				OR (
					N1.N_NAME = 'GERMANY'
					AND N2.N_NAME = 'FRANCE'
				)
			)
			AND L_SHIPDATE BETWEEN date '1995-01-01' AND date '1996-12-31'
	) AS SHIPPING
GROUP BY SUPP_NATION,
	CUST_NATION,
	L_YEAR
ORDER BY SUPP_NATION,
	CUST_NATION,
	L_YEAR;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `S_SUPPKEY`, `L_SUPPKEY`, `O_ORDERKEY`, `C_CUSTKEY`, `N_NATIONKEY` e `L_SHIPDATE`.

### Segunda Consulta:
```sql
SELECT O_YEAR,
	SUM(
		CASE
			WHEN NATION = 'BRAZIL' THEN VOLUME
			ELSE 0
		END
	) / SUM(VOLUME) AS MKT_SHARE
FROM (
		SELECT EXTRACT(
				YEAR
				FROM O_ORDERDATE
			) AS O_YEAR,
			L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS VOLUME,
			N2.N_NAME AS NATION
		FROM PART,
			SUPPLIER,
			LINEITEM,
			ORDERS,
			CUSTOMER,
			NATION N1,
			NATION N2,
			REGION
		WHERE P_PARTKEY = L_PARTKEY
			AND S_SUPPKEY = L_SUPPKEY
			AND L_ORDERKEY = O_ORDERKEY
			AND O_CUSTKEY = C_CUSTKEY
			AND C_NATIONKEY = N1.N_NATIONKEY
			AND N1.N_REGIONKEY = R_REGIONKEY
			AND R_NAME = 'AMERICA'
			AND S_NATIONKEY = N2.N_NATIONKEY
			AND O_ORDERDATE BETWEEN date '1995-01-01' AND date '1996-12-31'
			AND P_TYPE = 'ECONOMY ANODIZED STEEL'
	) AS ALL_NATIONS
GROUP BY O_YEAR
ORDER BY O_YEAR;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `P_PARTKEY`, `L_PARTKEY`, `S_SUPPKEY`, `L_SUPPKEY`, `O_ORDERKEY`, `C_CUSTKEY`, `N_NATIONKEY` e `O_ORDERDATE`.

### Terceira Consulta:
```sql
select p_brand,
	p_type,
	p_size,
	count(distinct ps_suppkey) as supplier_cnt
from partsupp,
	part
where p_partkey = ps_partkey
	and p_brand <> 'Brand#45'
	and p_type not like 'MEDIUM POLISHED%'
	and p_size in (49, 14, 23, 45, 19, 3, 36, 9)
	and ps_suppkey not in (
		select s_suppkey
		from supplier
		where s_comment like '%Customer%Complaints%'
	)
group by p_brand,
	p_type,
	p_size
order by supplier_cnt desc,
	p_brand,
	p_type,
	p_size;
```
- Criação de Índice: Certifique-se de ter índices em `PARTSUPP.PS_PARTKEY`, `PARTSUPP.PS_SUPPKEY` e `PART.P_PARTKEY` para otimizar as condições de junção.
### Quarta Consulta:
```sql
select c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice,
	sum(l_quantity)
from customer,
	orders,
	lineitem
where o_orderkey in (
		select l_orderkey
		from lineitem
		group by l_orderkey
		having sum(l_quantity) > 300
	)
	and c_custkey = o_custkey
	and o_orderkey = l_orderkey
group by c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice
order by o_totalprice desc,
	o_orderdate;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `C_CUSTKEY`, `O_ORDERKEY` e `L_ORDERKEY`.
### Quinta Consulta:
```sql
select sum(l_extendedprice * (1 - l_discount)) as revenue
from lineitem,
	part
where (
		p_partkey = l_partkey
		and p_brand = 'Brand#12'
		and p_container in (
			'SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
			and l_quantity >= 1
			and l_quantity <= 1 + 10
			and p_size between 1 and 5
			and l_shipmode in ('AIR ', 'AIR REG')
			and l_shipinstruct = 'DELIVER IN PERSON'
		)
		or (
			p_partkey = l_partkey
			and p_brand = 'Brand#23'
			and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
			and l_quantity >= 10
			and l_quantity <= 10 + 10
			and p_size between 1 and 10
			and l_shipmode in ('AIR', 'AIR REG')
			and l_shipinstruct = 'DELIVER IN PERSON'
		)
		or (
			p_partkey = l_partkey
			and p_brand = 'Brand#34'
			and p_container in (
				'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
				and l_quantity >= 20
				and l_quantity <= 20 + 10
				and p_size between 1 and 15
				and l_shipmode in ('AIR', 'AIR REG')
				and l_shipinstruct = 'DELIVER IN PERSON'
			);
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `p_partkey` e `l_partkey`. Além disso, índices nas colunas de filtragem como `p_brand`, `p_container`, `l_quantity`, `p_size`, `l_shipmode` e `l_shipinstruct` podem melhorar o desempenho.
### Sexta Consulta:
Find the top 10 customers with the highest total revenue
```sql
WITH CustomerRevenue AS (
    SELECT
        C_CUSTKEY,
        C_NAME,
        SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS TotalRevenue
    FROM
        CUSTOMER
        JOIN ORDERS ON CUSTOMER.C_CUSTKEY = ORDERS.O_CUSTKEY
        JOIN LINEITEM ON ORDERS.O_ORDERKEY = LINEITEM.L_ORDERKEY
    GROUP BY
        C_CUSTKEY,
        C_NAME
)
SELECT
    C_NAME,
    TotalRevenue
FROM
    CustomerRevenue
ORDER BY
    TotalRevenue DESC
LIMIT 10;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `C_CUSTKEY` em CUSTOMER e `O_CUSTKEY` em ORDERS.
### Sétima Consulta:
Calculate the rolling average of order total prices for each customer
```sql
WITH CustomerOrderTotals AS (
    SELECT
        O_CUSTKEY,
        O_ORDERKEY,
        O_TOTALPRICE,
        AVG(O_TOTALPRICE) OVER (PARTITION BY O_CUSTKEY ORDER BY O_ORDERKEY) AS RollingAvgTotalPrice
    FROM
        ORDERS
)
SELECT
    C_NAME,
    O_ORDERKEY,
    O_TOTALPRICE,
    RollingAvgTotalPrice
FROM
    CustomerOrderTotals
    JOIN CUSTOMER ON CustomerOrderTotals.O_CUSTKEY = CUSTOMER.C_CUSTKEY;

```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `O_CUSTKEY`, `O_ORDERKEY` e `L_ORDERKEY`.
### Oitava Consulta:
Calculate the total revenue for each region and year
```sql
SELECT
    R_NAME AS REGION,
    EXTRACT(YEAR FROM O_ORDERDATE) AS ORDER_YEAR,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS TOTAL_REVENUE
FROM
    REGION,
    NATION,
    CUSTOMER,
    ORDERS,
    LINEITEM
WHERE
    REGION.R_REGIONKEY = NATION.N_REGIONKEY
    AND NATION.N_NATIONKEY = CUSTOMER.C_NATIONKEY
    AND CUSTOMER.C_CUSTKEY = ORDERS.O_CUSTKEY
    AND ORDERS.O_ORDERKEY = LINEITEM.L_ORDERKEY
GROUP BY
    R_NAME,
    EXTRACT(YEAR FROM O_ORDERDATE)
ORDER BY
    REGION,
    ORDER_YEAR;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `REGION.R_REGIONKEY`, `NATION.N_REGIONKEY`, `CUSTOMER.C_NATIONKEY`, `ORDERS.O_CUSTKEY` e `LINEITEM.L_ORDERKEY`.
### Nona Consulta:
Find the customers who have placed orders for at least three different product types
```sql
SELECT
    C_NAME,
    COUNT(DISTINCT P_TYPE) AS DISTINCT_PRODUCT_TYPES
FROM
    CUSTOMER,
    ORDERS,
    LINEITEM,
    PART
WHERE
    CUSTOMER.C_CUSTKEY = ORDERS.O_CUSTKEY
    AND ORDERS.O_ORDERKEY = LINEITEM.L_ORDERKEY
    AND LINEITEM.L_PARTKEY = PART.P_PARTKEY
GROUP BY
    C_NAME
HAVING
    COUNT(DISTINCT P_TYPE) >= 3
ORDER BY
    DISTINCT_PRODUCT_TYPES DESC,
    C_NAME;

```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `CUSTOMER.C_CUSTKEY`, `ORDERS.O_ORDERKEY` e `LINEITEM.L_PARTKEY`.

### Décima Consulta:
Identify suppliers who have not supplied parts for a specific brand
```sql
SELECT
    S_SUPPKEY,
    S_NAME,
    S_NATIONKEY
FROM
    SUPPLIER
WHERE
    S_SUPPKEY NOT IN (
        SELECT DISTINCT PS_SUPPKEY
        FROM PARTSUPP,
             PART
        WHERE PARTSUPP.PS_PARTKEY = PART.P_PARTKEY
          AND P_BRAND = 'Brand#12'
    )
ORDER BY
    S_SUPPKEY;
```
- Criação de Índice: Certifique-se de ter índices nas colunas usadas nas condições de junção, como `SUPPLIER.S_SUPPKEY`, `PARTSUPP.PS_SUPPKEY` e `PARTSUPP.PS_PARTKEY`.

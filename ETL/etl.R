library(readr)

customer <- read_delim("customer.tbl", delim = "|",
                       escape_double = FALSE, col_names = FALSE,
                       trim_ws = TRUE)
colnames(customer) <- c("C_CUSTKEY", "C_NAME", "C_ADDRESS", "C_NATIONKEY", "C_PHONE", 
                        "C_ACCTBAL", "C_MKTSEGMENT", "C_COMMENT")
customer[,ncol(customer)] <- NULL

lineitem <- read_delim("lineitem.tbl", delim = "|",
                       escape_double = FALSE, col_names = FALSE,
                       col_types = cols(X11 = col_date(format = "%Y-%m-%d"),
                                        X12 = col_date(format = "%Y-%m-%d"),
                                        X13 = col_date(format = "%Y-%m-%d")),
                       trim_ws = TRUE)
colnames(lineitem) <- c("L_ORDERKEY", "L_PARTKEY", "L_SUPPKEY", "L_LINENUMBER", "L_QUANTITY", 
                        "L_EXTENDEDPRICE", "L_DISCOUNT", "L_TAX", "L_RETURNFLAG", "L_LINESTATUS", 
                        "L_SHIPDATE", "L_COMMITDATE", "L_RECEIPTDATE", "L_SHIPINSTRUCT", "L_SHIPMODE",
                        "L_COMMENT")
lineitem[,ncol(lineitem)] <- NULL

nation <- read_delim("nation.tbl", delim = "|",
                     escape_double = FALSE, col_names = FALSE,
                     trim_ws = TRUE)
colnames(nation) <- c("N_NATIONKEY", "N_NAME", "N_REGIONKEY", "N_COMMENT")
nation[,ncol(nation)] <- NULL

orders <- read_delim("orders.tbl", delim = "|", 
                     escape_double = FALSE, col_names = FALSE, 
                     trim_ws = TRUE)
colnames(orders) <- c("O_ORDERKEY", "O_CUSTKEY", "O_ORDERSTATUS", "O_TOTALPRICE", "O_ORDERDATE",
                      "O_ORDERPRIORITY", "O_CLERK", "O_SHIPPRIORITY", "O_COMMENT")
orders[,ncol(orders)] <- NULL

part <- read_delim("part.tbl", delim = "|", 
                   escape_double = FALSE, col_names = FALSE, 
                   trim_ws = TRUE)
colnames(part) <- c("P_PARTKEY", "P_NAME", "P_MFGR", "P_BRAND", "P_TYPE",
                      "P_SIZE", "P_CONTAINER", "P_RETAILPRICE", "O_P_COMMENTCOMMENT")
part[,ncol(part)] <- NULL


partsupp <- read_delim("partsupp.tbl", delim = "|", 
                   escape_double = FALSE, col_names = FALSE, 
                   trim_ws = TRUE)
colnames(partsupp) <- c("PS_PARTKEY", "PS_SUPPKEY", "PS_AVAILQTY", "PS_SUPPLYCOST", "PS_COMMENT")
partsupp[,ncol(partsupp)] <- NULL

region <- read_delim("region.tbl", delim = "|", 
                       escape_double = FALSE, col_names = FALSE, 
                       trim_ws = TRUE)
colnames(region) <- c("R_REGIONKEY", "R_NAME", "R_COMMENT")
region[,ncol(region)] <- NULL

supplier <- read_delim("supplier.tbl", delim = "|", 
                     escape_double = FALSE, col_names = FALSE, 
                     trim_ws = TRUE)
colnames(supplier) <- c("S_SUPPKEY", "S_NAME", "S_ADDRESS", "S_NATIONKEY", "S_PHONE", 
                        "S_ACCTBAL", "S_COMMENT")
supplier[,ncol(supplier)] <- NULL

bulk_insert <- function(conn, data, table_name) {
  table_name_aux <- sprintf("%s_aux", table_name)
  dbWriteTable(conn, table_name_aux, data)  
}

drop_aux_tables <- function(conn) {
  dbSendUpdate(conn, 'drop table customer_aux')
  dbSendUpdate(conn, 'drop table lineitem_aux')
  dbSendUpdate(conn, 'drop table nation_aux')
  dbSendUpdate(conn, 'drop table orders_aux')
  dbSendUpdate(conn, 'drop table part_aux')
  dbSendUpdate(conn, 'drop table partsupp_aux')  
  dbSendUpdate(conn, 'drop table region_aux')   
  dbSendUpdate(conn, 'drop table supplier_aux')    
}

truncate_tables <- function(conn) {
  dbSendUpdate(conn, 'truncate table CUSTOMER')
  dbSendUpdate(conn, 'truncate table LINEITEM')
  dbSendUpdate(conn, 'truncate table NATION')
  dbSendUpdate(conn, 'truncate table ORDERS')
  dbSendUpdate(conn, 'truncate table PART')
  dbSendUpdate(conn, 'truncate table PARTSUPP')  
  dbSendUpdate(conn, 'truncate table REGION')   
  dbSendUpdate(conn, 'truncate table SUPPLIER')    
}

if (FALSE) {
  #https://www.oracle.com/br/database/technologies/appdev/jdbc-downloads.html
  library(RJDBC)
  library(DBI)
  drv <- JDBC("oracle.jdbc.OracleDriver",classPath="ojdbc8.jar")
  conn <- dbConnect(drv, "jdbc:oracle:thin:@//localhost:1521/xe", "TPCH", "tpch2023#")

  bulk_insert(conn, customer, 'customer')
  bulk_insert(conn, lineitem, 'lineitem')
  bulk_insert(conn, nation, 'nation')
  bulk_insert(conn, orders, 'orders')
  bulk_insert(conn, part, 'part')
  bulk_insert(conn, partsupp, 'partsupp')
  bulk_insert(conn, region, 'region')
  bulk_insert(conn, supplier, 'supplier')
  
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "customer", "customer_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "nation", "nation_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "part", "part_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "partsupp", "partsupp_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "region", "region_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "supplier", "supplier_aux"))
  dbSendUpdate(conn,
    "INSERT INTO LINEITEM SELECT  L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY,
        L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS,
        TO_TIMESTAMP(L_SHIPDATE, 'YYYY-MM-DD'),
        TO_TIMESTAMP(L_COMMITDATE, 'YYYY-MM-DD'),
        TO_TIMESTAMP(L_RECEIPTDATE, 'YYYY-MM-DD'),
        L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT FROM LINEITEM_AUX")
  dbSendUpdate(conn,
    "INSERT INTO ORDERS
        SELECT O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE,
        TO_TIMESTAMP(O_ORDERDATE, 'YYYY-MM-DD'),
        O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT
        FROM ORDERS_AUX")  
  
  drop_aux_tables(conn)  
}

if (FALSE) {
  #https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server?view=sql-server-ver16
  library(RJDBC)
  library(DBI)
  drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver",classPath="mssql-jdbc-12.4.0.jre8.jar")
  conn <- DBI::dbConnect(drv, url='jdbc:sqlserver://127.0.0.1;databaseName=tpch;encrypt=true;trustServerCertificate=true' , user="tpch", password="tpch2023#")
  print(conn)

  bulk_insert(conn, customer, 'customer')
  bulk_insert(conn, lineitem, 'lineitem')
  bulk_insert(conn, nation, 'nation')
  bulk_insert(conn, orders, 'orders')
  bulk_insert(conn, part, 'part')
  bulk_insert(conn, partsupp, 'partsupp')
  bulk_insert(conn, region, 'region')
  bulk_insert(conn, supplier, 'supplier')
  
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "customer", "customer_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "nation", "nation_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "part", "part_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "partsupp", "partsupp_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "region", "region_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "supplier", "supplier_aux"))
  dbSendUpdate(conn,
               "INSERT INTO LINEITEM SELECT  L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY,
        L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS,
        convert(date, L_SHIPDATE, 126),
        convert(date, L_COMMITDATE, 126),
        convert(date, L_RECEIPTDATE, 126),
        L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT FROM LINEITEM_AUX")
  dbSendUpdate(conn,
               "INSERT INTO ORDERS
        SELECT O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE,
        convert(date, O_ORDERDATE, 126),
        O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT
        FROM ORDERS_AUX")  
  
  drop_aux_tables(conn)  
}

if (FALSE) {
  #https://jdbc.postgresql.org/download/
  library(RJDBC)
  library(DBI)
  driver <- JDBC(driverClass = "org.postgresql.Driver", classPath = "postgresql-42.6.0.jar", identifier.quote = "'") 
  conn <- dbConnect(driver, url="jdbc:postgresql://127.0.0.1:5432/tpch", user="tpch", password="tpch2023#")  
  print(conn)
  
  bulk_insert(conn, customer, 'customer')
  bulk_insert(conn, lineitem, 'lineitem')
  bulk_insert(conn, nation, 'nation')
  bulk_insert(conn, orders, 'orders')
  bulk_insert(conn, part, 'part')
  bulk_insert(conn, partsupp, 'partsupp')
  bulk_insert(conn, region, 'region')
  bulk_insert(conn, supplier, 'supplier')  
  
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "customer", "customer_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "nation", "nation_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "part", "part_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "partsupp", "partsupp_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "region", "region_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "supplier", "supplier_aux"))

  dbSendUpdate(conn,
               "INSERT INTO LINEITEM SELECT  L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY,
        L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS,
        TO_TIMESTAMP(L_SHIPDATE, 'YYYY-MM-DD'),
        TO_TIMESTAMP(L_COMMITDATE, 'YYYY-MM-DD'),
        TO_TIMESTAMP(L_RECEIPTDATE, 'YYYY-MM-DD'),
        L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT FROM LINEITEM_AUX")
  dbSendUpdate(conn,
               "INSERT INTO ORDERS
        SELECT O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE,
        TO_TIMESTAMP(O_ORDERDATE, 'YYYY-MM-DD'),
        O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT
        FROM ORDERS_AUX")  
  
  drop_aux_tables(conn)  
}

if (FALSE) {
  #https://dev.mysql.com/downloads/file/?id=520816
  library(RJDBC)
  drv <- JDBC("com.mysql.jdbc.Driver",
              "mysql-connector-j-8.1.0.jar",
              identifier.quote="`")
  conn <- dbConnect(drv, "jdbc:mysql://127.0.0.1/tpch", "tpch", "tpch2023#")  
  print(conn)
  
  bulk_insert(conn, customer, 'customer')
  bulk_insert(conn, lineitem, 'lineitem')
  bulk_insert(conn, nation, 'nation')
  bulk_insert(conn, orders, 'orders')
  bulk_insert(conn, part, 'part')
  bulk_insert(conn, partsupp, 'partsupp')
  bulk_insert(conn, region, 'region')
  bulk_insert(conn, supplier, 'supplier')    
  
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "CUSTOMER", "customer_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "NATION", "nation_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "PART", "part_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "PARTSUPP", "partsupp_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "REGION", "region_aux"))
  dbSendUpdate(conn, sprintf('insert into %s select * from %s', "SUPPLIER", "supplier_aux"))

  dbSendUpdate(conn, "INSERT INTO LINEITEM SELECT L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY,
        L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS,
        STR_TO_DATE(L_SHIPDATE, '%Y-%m-%d'),
        STR_TO_DATE(L_COMMITDATE, '%Y-%m-%d'),
        STR_TO_DATE(L_RECEIPTDATE, '%Y-%m-%d'),
        L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT FROM lineitem_aux")
  dbSendUpdate(conn, "INSERT INTO ORDERS SELECT O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE,
		    STR_TO_DATE(O_ORDERDATE, '%Y-%m-%d'),
        O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT
        FROM orders_aux") 
  
  drop_aux_tables(conn)  
}

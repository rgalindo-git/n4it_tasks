--NOTE, Unable to execute on APEX, due to limited privileges

CREATE TABLESPACE data1 
DATAFILE 'tbs1_data1.dbf' 
SIZE 1m;
   
CREATE TABLESPACE data2 
DATAFILE 'tbs1_data2.dbf' 
SIZE 1m;   
   
CREATE TABLESPACE data3 
DATAFILE 'tbs1_data3.dbf' 
SIZE 1m;

CREATE TABLESPACE data4 
DATAFILE 'tbs1_data4.dbf' 
SIZE 1m;

CREATE TABLESPACE data5 
DATAFILE 'tbs1_data5.dbf' 
SIZE 1m;


ALTER TABLE item_loc_soh MODIFY
PARTITION BY HASH(dept) 
PARTITIONS 5 
STORE IN (data1, data2, data3, data4, data5);


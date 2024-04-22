/*
####COMMENTS
task #1 
I set constrains in all tables, setting primary keys on tables ITEM and LOC and corresponding foreign keys on ITEM_LOC_SOH. 
The primary keys had NOVALIDATE ENABLE to bypass exixting records that may generate errors(e.g. duplicates).
After seting the foreign keys, I created an INDEX for each one and associated with the related primary key to improve performance
*/

ALTER TABLE item ADD CONSTRAINT i_pk PRIMARY KEY (item)
ENABLE NOVALIDATE;

ALTER TABLE loc ADD CONSTRAINT l_pk PRIMARY KEY (loc)
ENABLE NOVALIDATE;

ALTER TABLE item_loc_soh  ADD CONSTRAINT ils_item_fk FOREIGN KEY (item)
REFERENCES item(item);

CREATE INDEX ils_item_idx ON item_loc_soh(item);

ALTER TABLE item_loc_soh  ADD CONSTRAINT ils_loc_fk FOREIGN KEY (loc)
REFERENCES loc(loc);

CREATE INDEX ils_loc_idx  ON item_loc_soh(loc);

COMMIT;

/*
task #2 
As these Tables are considerably large, ITEM_LOC_SOH the largest of all, and I would spend reasonable amout of time to verify the proportion of data usage
I would use Hash Partitioning to spread the tables on 5 diferent tablespaces

Please note this answer is just part answered as I do not have privelege Role on APEX to implement these changes. 
On my private DB I manage to create the tablespaces as SYSDBA.
*/

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

--EXAMPLE with TABLE item_loc_soh
ALTER TABLE item_loc_soh MODIFY
PARTITION BY HASH(dept) 
PARTITIONS 5 
STORE IN (data1, data2, data3, data4, data5);

--
/*
task #3
Seting isolation level to read committed can improve concurrency and impose less row contention locks. 
This isolation level, however, compromises data consistency so it could be set during standard business hours using the bellow trigger SECURE_ISO and the procedure  UPD_ISOLATION before any DML on  the table (e.g.) item_loc_soh.
Diferent times could also be set if there is a need of higher consistency inbetween standard business hours
*/


create or replace TRIGGER secure_iso
  BEFORE INSERT OR UPDATE OR DELETE ON item_loc_soh
BEGIN
  upd_isolation;
END secure_iso;


create or replace PROCEDURE upd_isolation
IS
BEGIN
  IF TO_CHAR (SYSDATE, 'HH24:MI') NOT BETWEEN '08:00' AND '18:00'
        OR TO_CHAR (SYSDATE, 'DY') IN ('SAT', 'SUN') THEN


    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

  ELSE

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


  END IF;
END upd_isolation;


--task # 4. The following view was created joining the 3 tables without collumn duplication
-- Please note the script compiled in APEX without errors but would not return data, on my private DB was working fine

CREATE VIEW item_loc_soh_v AS
SELECT i.item AS ITEM ,i.dept AS DEPT , i.item_desc AS ITEM_DESC,
       l.loc AS LOC, l.loc_desc AS LOC_DESC,
       ils.unit_cost AS UNIT_COST, ils.stock_on_hand AS
FROM   item i, 
       loc l,
       item_loc_soh ils
WHERE  ils.item = i.item
  AND  ils.loc = l.loc;

COMMIT;


-- Task #5
/*In Order to create a table to associate users with the dept collumn, I need a collumn to have a relation one-to-many 
opposite to the collumn dept in the item table, that was many-to-one to improve consistency. I decide to create the TABLE dept as reference, just to 
insert the rows as unique primary key, then I reffer them as a foreign key in another TABLE users.
At last I created the PROCEDURE populate_dept to insert the dept numbers.

*/
CREATE TABLE dept(
    dept number(4) not null,
    dept_desc varchar2(25),
    CONSTRAINT dept_pk PRIMARY KEY(dept)
);


CREATE TABLE users(
    user_id number(4) not null,
    fname varchar2(25) not null,
    lname varchar2(25) not null,
    dept number(4),
    CONSTRAINT uid_pk PRIMARY KEY(user_id),
    CONSTRAINT dept_fk  FOREIGN KEY (dept) 
    REFERENCES dept(dept)
    );


create or replace PROCEDURE populate_dept
IS
   CURSOR c_pop_dept
   IS
   SELECT DISTINCT(i.dept) 
   from item i; 

   rec   c_pop_dept%ROWTYPE;
   l_dept_desc        varchar2(25):='No description';

BEGIN

   IF NOT c_pop_dept%ISOPEN THEN
   OPEN c_pop_dept;

      LOOP
      FETCH  c_pop_dept  INTO rec;
      EXIT WHEN c_pop_dept%NOTFOUND;
      INSERT INTO dept(dept, dept_desc) VALUES (rec.dept, l_dept_desc);
      END LOOP;

    COMMIT;
    END IF;
    CLOSE c_pop_dept;
    

END populate_dept;

-- Task #6
--View and package created on private DB, compiled on APEX but did not return data

create table item_loc_soh_total(
  item varchar2(25) not null,
  loc number(10) not null,
  dept number(4) not null,
  unit_cost number(20,4) not null,
  stock_on_hand number(12,4) not null,
  uc_soh number(12,4) not null,
  CONSTRAINT i_fk  FOREIGN KEY (item) 
    REFERENCES item(item),
  CONSTRAINT l_fk  FOREIGN KEY (loc) 
    REFERENCES loc(loc),
  CONSTRAINT dept_fk  FOREIGN KEY (dept) 
    REFERENCES dept(dept)
);





--PACKAGE HEAD
create or replace PACKAGE DML_unit_cost_total AS

PROCEDURE populate_uct;

END DML_unit_cost_total;


--PACKAGE BODY

create or replace PACKAGE BODY DML_unit_cost_total AS

-- ============================================================================
-- PROC: populate_uct
-- DESC: populate table item_loc_soh_total with data from ITEM, LOC and ITEM_LOC_SOH
-- NOTE:
--
-- ============================================================================

PROCEDURE populate_uct
IS
   CURSOR c_item_loc_soh
   IS
   SELECT i.item, 
          i.loc,
          i.dept,
          i.unit_cost,
          i.stock_on_hand 
     from item_loc_soh i; 

   rec             c_item_loc_soh%ROWTYPE;
   l_uc_soh_t      number(30,4);

BEGIN
   
   IF NOT c_item_loc_soh%ISOPEN THEN
   OPEN c_item_loc_soh;

      LOOP
      FETCH  c_item_loc_soh  INTO rec;
      l_uc_soh_t := TRUNC(rec.unit_cost * rec.stock_on_hand, 2) ;

      EXIT WHEN c_item_loc_soh%NOTFOUND;

      INSERT INTO
      item_loc_soh_total(
        item, 
        loc,
        dept,
        unit_cost,
        stock_on_hand,
        uc_soh)
      VALUES (
        rec.item, 
        rec.loc,
        rec.dept, 
        rec.unit_cost,
        rec.stock_on_hand,
        l_uc_soh_t);
      END LOOP;

    COMMIT;
    END IF;
    CLOSE c_item_loc_soh;

END populate_uct;

END DML_unit_cost_total;


-- Task #7

--Appologies, I am unable to create a this filter on APEX, I could create a package for this purpose but would not differ much from what was done on task #8.

-- Task #8

-- I used as base to the pipeline function the table item_loc_soh_total that has the most complete records
-- I started create the object type and a nested table type needed for the table functions:

create  TYPE TABLE_RES_OBJ AS OBJECT (
  item varchar2(25) ,
  loc number(10) ,
  dept number(4) ,
  unit_cost number,
  stock_on_hand number(12,4) ,
  uc_soh number(30,4)
     );

create TYPE TABLE_RES AS TABLE OF TABLE_RES_OBJ;

--Then, created a REF CURSOR type  to pass a dataset to the table functions
 
 CREATE OR REPLACE PACKAGE loc_pipe_mgr AUTHID DEFINER
IS
   TYPE c_location IS REF CURSOR
      RETURN item_loc_soh_total%ROWTYPE;

END loc_pipe_mgr;

--At last I created the pipeline table function with arguments for the specific collumns

create or replace FUNCTION loc_piped(rows_in loc_pipe_mgr.c_location)   
    
   RETURN TABLE_RES
   PIPELINED
   AUTHID DEFINER

AS
     TYPE l_loc_pip IS TABLE OF item_loc_soh_total%ROWTYPE
     INDEX BY PLS_INTEGER;
     l_loc  l_loc_pip;

BEGIN

   LOOP
    
      FETCH rows_in BULK COLLECT INTO l_loc LIMIT 100;

      EXIT WHEN l_loc.COUNT = 0;
      
      FOR l_row IN 1 .. l_loc.COUNT
      LOOP

      PIPE ROW (TABLE_RES_OBJ (l_loc (l_row).item, 
        l_loc (l_row).loc,
        l_loc (l_row).dept,
        l_loc (l_row).unit_cost,
        l_loc (l_row).stock_on_hand,
        l_loc (l_row).uc_soh));

      END LOOP;
   END LOOP;
  

   RETURN;
END loc_piped;


-- Tested some queries using the pipeline function, results as expected on my SQL Developer. 

SELECT * FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where dept = 40;
SELECT * FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where item = 130;
SELECT stock_on_Hand,uc_soh FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where dept = 15;
-- On APEX all the objects were compiled fine but I could not manage to test the queries 
-- because the table item_loc_soh_total was not populated on APEX



-- Task #9
-- Appologies, I am not familiar with Dynamic Data Sampling, despite understanding the concept I am able to answer this question

-- Task #10
-- Appologies, I do not understand this task, task #6 does not mention anything about a history table or adding date column to the new migrated table, 
-- I also don't understand what date should be added, if a random date or sysdate

-- Task #11
-- Appologies, I am not familiar with WORKLOAD REPOSITORY PDB report to be able to provide a satisfatory answer

-- Task #11 PERFORMANCE

/*
I created a very small python file to convert the Oracle table into a CSV file that was reasonably fast - see 19c_to_csv.py .
I am not so sure how reliable the data is, possibly would be better convert the table to a JSON object and then to a CSV file,
but as POC I think the convertion is satisfactory.

            import cx_Oracle
            import pandas as pd
            import time
            
            start_time = time.process_time() 
            conn = cx_Oracle.connect('hr/hr@localhost/orclpdb')
            
            for num in range(101,151):
                df = pd.read_sql_query('SELECT item, loc, dept, unit_cost,stock_on_hand, uc_soh FROM item_loc_soh_total WHERE loc = {}'.format(num) , conn)
                df.to_csv('location_{}.csv'.format(num), index=False)
            
            conn.close()     
            
            print((time.process_time()  - start_time) , " seconds")


The processing time was 4.5625  seconds to create 50 .csv files


*/

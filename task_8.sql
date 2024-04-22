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
-- On APEX all the objects were compiled fine but I could not manage to test the queries 
-- cause the table item_loc_soh_total was not populated


SELECT * FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where dept = 40;
SELECT * FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where item = 130;
SELECT stock_on_Hand,uc_soh FROM TABLE (loc_piped (CURSOR (SELECT * FROM item_loc_soh_total))) where dept = 15;

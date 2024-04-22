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
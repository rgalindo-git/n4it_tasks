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
--TABLE

create table item_loc_soh_total(
  item varchar2(25) not null,
  loc number(10) not null,
  dept number(4) not null,
  unit_cost number(20,4) not null,
  stock_on_hand number(12,4) not null,
  uc_soh number(30,4) not null,
  CONSTRAINT ilst_i_fk  FOREIGN KEY (item) 
    REFERENCES item(item),
  CONSTRAINT ilst_l_fk  FOREIGN KEY (loc) 
    REFERENCES loc(loc),
  CONSTRAINT ilst_d_fk  FOREIGN KEY (dept) 
    REFERENCES dept(dept)
);


COMMIT;


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
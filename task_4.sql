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


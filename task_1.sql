
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


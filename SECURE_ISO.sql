create or replace TRIGGER secure_iso
  BEFORE INSERT OR UPDATE OR DELETE ON item_loc_soh
BEGIN
  upd_isolation;
END secure_iso;


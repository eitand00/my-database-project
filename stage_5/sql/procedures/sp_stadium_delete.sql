CREATE OR REPLACE PROCEDURE sp_stadium_delete(p_sid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM STADIUM WHERE StadiumID = p_sid;
END $$;

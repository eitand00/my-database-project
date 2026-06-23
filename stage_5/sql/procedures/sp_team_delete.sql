CREATE OR REPLACE PROCEDURE sp_team_delete(p_code VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM TEAM WHERE TeamCode = p_code;
END $$;

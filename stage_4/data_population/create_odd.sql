CREATE OR REPLACE PROCEDURE create_odd(
    p_global_match_id INT,
    p_home_odd NUMERIC,
    p_draw_odd NUMERIC,
    p_away_odd NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_odd_id INT;
BEGIN
    -- ׳•׳׳™׳“׳¦׳™׳”: ׳”׳׳ ׳›׳‘׳¨ ׳™׳© ׳™׳—׳¡׳™׳ ׳׳׳©׳—׳§ ׳”׳–׳”?
    IF EXISTS (SELECT 1 FROM odds WHERE global_match_id = p_global_match_id) THEN
        RAISE EXCEPTION 'Data Error: Odds already exist for match %', p_global_match_id;
    END IF;

    -- ׳•׳׳™׳“׳¦׳™׳” ׳ ׳•׳¡׳₪׳×: ׳”׳™׳—׳¡ ׳—׳™׳™׳‘ ׳׳”׳™׳•׳× ׳’׳“׳•׳ ׳-1 (׳׳™ ׳׳₪׳©׳¨ ׳׳”׳׳¨ ׳•׳׳”׳¨׳•׳•׳™׳— ׳₪׳—׳•׳× ׳׳׳” ׳©׳©׳׳×)
    IF p_home_odd <= 1.0 OR p_draw_odd <= 1.0 OR p_away_odd <= 1.0 THEN
         RAISE EXCEPTION 'Logic Error: Betting odds must be greater than 1.0';
    END IF;

    SELECT COALESCE(MAX(odd_id), 0) + 1 INTO v_new_odd_id FROM odds;

    -- DML: ׳”׳•׳¡׳₪׳× ׳™׳—׳¡׳™ ׳”׳–׳›׳™׳™׳”
    INSERT INTO odds (global_match_id, home_win_odd, draw_odd, away_win_odd, update_date, odd_id)
    VALUES (p_global_match_id, p_home_odd, p_draw_odd, p_away_odd, CURRENT_DATE, v_new_odd_id);

    -- ׳”׳¢׳¨׳”: ׳׳ ׳©׳׳×׳™ ׳₪׳” RAISE NOTICE ׳›׳“׳™ ׳©׳׳ ׳™׳¦׳™׳£ ׳׳›׳ ׳׳× ׳”׳׳¡׳ ׳‘-800 ׳”׳•׳“׳¢׳•׳× ׳‘׳¨׳¦׳£.
END;
$$;
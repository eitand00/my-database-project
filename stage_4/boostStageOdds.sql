CREATE OR REPLACE PROCEDURE Mass_Update_Stage_Odds(p_stage VARCHAR, p_boost_factor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_match RECORD;
    v_counter INT := 0;
BEGIN
    -- סמן מרומז (Implicit Cursor) משולב בלולאת FOR
    FOR v_match IN 
        SELECT gm.GlobalMatchID 
        FROM GLOBAL_MATCH gm
        JOIN MATCH m ON gm.WCMatchID = m.MatchID
        WHERE m.Stage = p_stage AND gm.MatchSource = 'WorldCup'
    LOOP
        -- DML - מתוקן ל-odd
        UPDATE odds
        SET 
            home_win_odd = home_win_odd * p_boost_factor,
            away_win_odd = away_win_odd * p_boost_factor,
            draw_odd = draw_odd * p_boost_factor
        WHERE global_match_id = v_match.GlobalMatchID;
        
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Successfully boosted odds for % matches in stage %', v_counter, p_stage;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error encountered during mass update: %', SQLERRM;
        -- מכיוון שזו פרוצדורה, אנחנו יכולים לבטל את העסקה במקרה של שגיאה
        ROLLBACK;
END;
$$;
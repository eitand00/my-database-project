CREATE OR REPLACE PROCEDURE Mass_Update_Stage_Odds(p_stage VARCHAR, p_boost_factor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_id INT;
    v_counter INT := 0;
    
    -- הגדרת סמן מפורש (Explicit Cursor)
    v_match_cursor CURSOR FOR 
        SELECT gm.GlobalMatchID 
        FROM GLOBAL_MATCH gm
        JOIN MATCH m ON gm.WCMatchID = m.MatchID
        WHERE m.Stage = p_stage AND gm.MatchSource = 'WorldCup';
BEGIN
    -- פתיחת הסמן המפורש
    OPEN v_match_cursor;
    
    LOOP
        -- שליפת הנתונים אחד אחד לתוך המשתנה
        FETCH v_match_cursor INTO v_match_id;
        
        -- תנאי יציאה: כשאין יותר שורות בסמן
        EXIT WHEN NOT FOUND;

        -- DML: עדכון היחסים למשחק הספציפי
        UPDATE odds
        SET 
            home_win_odd = home_win_odd * p_boost_factor,
            away_win_odd = away_win_odd * p_boost_factor,
            draw_odd = draw_odd * p_boost_factor
        WHERE global_match_id = v_match_id;
        
        v_counter := v_counter + 1;
    END LOOP;
    
    -- סגירת הסמן בסיום השימוש
    CLOSE v_match_cursor;
    
    RAISE NOTICE 'Successfully boosted odds for % matches in stage %', v_counter, p_stage;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error encountered during mass update: %', SQLERRM;
        ROLLBACK;
END;
$$;
DO $$
DECLARE
    v_match_record RECORD;
    v_home_odd NUMERIC;
    v_draw_odd NUMERIC;
    v_away_odd NUMERIC;
    v_counter INT := 0;
BEGIN
    RAISE NOTICE '--- Starting Missing Odds Seeding Process ---';

    -- לולאה שעוברת רק על משחקי מונדיאל *שאין* להם ייצוג בטבלת odds
    FOR v_match_record IN
        SELECT gm.GlobalMatchID
        FROM GLOBAL_MATCH gm
        LEFT JOIN odds o ON gm.GlobalMatchID = o.global_match_id
        WHERE gm.MatchSource = 'WorldCup' AND o.global_match_id IS NULL
    LOOP
        -- יצירת יחסי זכייה אקראיים (עם 2 ספרות אחרי הנקודה, דרך הפונקציה ROUND)
        -- היחסים בדרך כלל נעים בין 1.2 ל-4.5 בערך במשחקי כדורגל
        v_home_odd := round((random() * 3.0 + 1.2)::numeric, 2);
        v_draw_odd := round((random() * 2.0 + 2.5)::numeric, 2);
        v_away_odd := round((random() * 3.5 + 1.5)::numeric, 2);
        -- הפעלת הפרוצדורה
        CALL create_odd(v_match_record.GlobalMatchID, v_home_odd, v_draw_odd, v_away_odd);

        v_counter := v_counter + 1;
    END LOOP;

    RAISE NOTICE 'Success: Generated and inserted missing odds for % historical matches.', v_counter;
    RAISE NOTICE 'Database is now fully mapped and ready for betting!';
END;
$$;
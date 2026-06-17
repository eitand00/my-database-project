DO $$
DECLARE
    -- משתני הבוט החדש
    v_bot_name VARCHAR := 'Crowd_Wisdom_Bot';
    v_bot_email VARCHAR := 'bot_' || floor(random() * 10000)::TEXT || '@jct-betting.com';
    v_bot_balance NUMERIC := 100000.0;
    v_bot_id INT;
    
    -- משתני ניהול הסמן
    v_match_id INT;
    v_bettor_cursor refcursor;
    v_bettor_name VARCHAR;
    v_amount NUMERIC;
    v_guess VARCHAR;
    v_status VARCHAR;
    
    -- משתני אגרגציה (סיכום כספים)
    v_home_money NUMERIC := 0;
    v_away_money NUMERIC := 0;
    v_draw_money NUMERIC := 0;
    v_chosen_prediction VARCHAR;
    v_bot_bet_amount NUMERIC := 1500.0; -- הבוט תמיד מהמר בסכום גבוה
BEGIN
    RAISE NOTICE '--- Starting Main Program 2: Algorithm "Wisdom of the Crowds" ---';

    -- 1. [זימון פרוצדורה] רישום הבוט האוטומטי למערכת
    CALL create_user(v_bot_name, v_bot_email, v_bot_balance);
    SELECT user_id INTO v_bot_id FROM users WHERE email = v_bot_email;

    -- חיפוש משחק שיש עליו מספר הימורים כדי שיהיה מעניין לנתח
    SELECT global_match_id INTO v_match_id 
    FROM bets 
    WHERE global_match_id IS NOT NULL 
    GROUP BY global_match_id 
    HAVING COUNT(*) > 1 
    LIMIT 1;

    IF v_match_id IS NOT NULL THEN
        RAISE NOTICE 'Market Analysis: Scanning sentiment for Match ID %...', v_match_id;
        
        -- 2. [זימון פונקציה] פתיחת מצביע לכל ההימורים של המשחק הזה
        v_bettor_cursor := Get_Match_Bettors_RefCursor(v_match_id);
        
        -- ריצה על הסמן וסיכום הכספים
        LOOP
            FETCH v_bettor_cursor INTO v_bettor_name, v_amount, v_guess, v_status;
            EXIT WHEN NOT FOUND;
            
            IF v_guess = 'Home' THEN
                v_home_money := v_home_money + v_amount;
            ELSIF v_guess = 'Away' THEN
                v_away_money := v_away_money + v_amount;
            ELSIF v_guess = 'Draw' THEN
                v_draw_money := v_draw_money + v_amount;
            END IF;
        END LOOP;
        CLOSE v_bettor_cursor;

        RAISE NOTICE 'Money Distribution -> Home: %, Draw: %, Away: %', v_home_money, v_draw_money, v_away_money;

        -- לוגיקת קבלת ההחלטה (מציאת המקסימום)
        IF v_home_money >= v_away_money AND v_home_money >= v_draw_money THEN
            v_chosen_prediction := 'Home';
        ELSIF v_away_money >= v_home_money AND v_away_money >= v_draw_money THEN
            v_chosen_prediction := 'Away';
        ELSE
            v_chosen_prediction := 'Draw';
        END IF;

        RAISE NOTICE 'Algorithm Conclusion: Most money is on "%". Executing strategic bot bet...', v_chosen_prediction;

        -- 3. [זימון פרוצדורה - שימוש חוזר] ביצוע ההימור בפועל לפי מסקנת האלגוריתם
        CALL create_bet(v_bot_id, v_match_id, v_bot_bet_amount, v_chosen_prediction);

    ELSE
        RAISE NOTICE 'Analysis Aborted: Not enough betting volume found on any single match.';
    END IF;

    RAISE NOTICE '--- Main Program 2 Completed Successfully ---';
END;
$$;
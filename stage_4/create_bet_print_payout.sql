DO $$
DECLARE
    v_existing_user_id INT;
    v_match_with_odds INT;
    v_bet_amount NUMERIC;
    v_predictions TEXT[] := ARRAY['Home', 'Draw', 'Away'];
    v_random_prediction VARCHAR;
    v_latest_bet_id INT;
    v_potential_payout NUMERIC;
BEGIN
    RAISE NOTICE '--- Starting Main Program 1: Bet Placement & Payout Calculation ---';

    FOR i IN 1..3 LOOP
        -- 1. שליפת משתמש קיים באקראי מתוך המערכת
        SELECT user_id INTO v_existing_user_id FROM users ORDER BY random() LIMIT 1;

        -- 2. שליפת משחק ש*בוודאות* יש עליו יחסי זכייה מוגדרים
        SELECT global_match_id INTO v_match_with_odds FROM odds ORDER BY random() LIMIT 1;

        -- 3. הגרלת סכום הימור חוקי ותוצאה
        v_bet_amount := floor(random() * 150 + 50);
        v_random_prediction := v_predictions[1 + floor(random() * array_length(v_predictions, 1))];

        -- 4. [זימון פרוצדורה] ביצוע ההימור בפועל על המשתמש הקיים (השם תוקן)
        CALL create_bet(v_existing_user_id, v_match_with_odds, v_bet_amount, v_random_prediction);
        
        -- 5. שליפת ה-ID של ההימור האחרון שבוצע על ידי המשתמש הנוכחי
        SELECT MAX(bet_id) INTO v_latest_bet_id FROM bets WHERE user_id = v_existing_user_id;
        
        -- 6. [זימון פונקציה] חישוב הרווח הצפוי עבור ההימור הספציפי שזה עתה נוצר
        v_potential_payout := Calculate_Potential_Payout(v_latest_bet_id);
        
        RAISE NOTICE 'Analytics: Bet ID % has a calculated potential payout of: %', v_latest_bet_id, v_potential_payout;
        RAISE NOTICE '---------------------------------------------------------';
    END LOOP;

    RAISE NOTICE '--- Main Program 1 Completed Successfully ---';
END;
$$;
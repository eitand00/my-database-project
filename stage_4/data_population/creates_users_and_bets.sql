DO $$
DECLARE
    -- מערכים לשמות אמיתיים
    v_first_names TEXT[] := ARRAY['David', 'Sarah', 'Daniel', 'Yael', 'Omer', 'Michal', 'Adam', 'Noa'];
    v_last_names TEXT[] := ARRAY['Cohen', 'Levi', 'Smith', 'Brown', 'Mizrachi', 'Katz', 'Golan', 'Friedman'];
    v_first_name VARCHAR;
    v_last_name VARCHAR;

    -- משתנים לפרטי המשתמש
    v_random_name VARCHAR;
    v_random_email VARCHAR;
    v_random_balance NUMERIC;
    v_new_user_id INT;
    
    -- משתנים לפרטי ההימור
    v_random_match_id INT;
    v_bet_amount NUMERIC;
    v_predictions TEXT[] := ARRAY['Home', 'Draw', 'Away'];
    v_random_prediction VARCHAR;
BEGIN
    RAISE NOTICE '--- Starting System Test & Data Seeding ---';

    -- לולאה ליצירת 3 משתמשים חדשים
    FOR i IN 1..3 LOOP
        -- הגרלת שם פרטי ושם משפחה
        v_first_name := v_first_names[1 + floor(random() * array_length(v_first_names, 1))];
        v_last_name := v_last_names[1 + floor(random() * array_length(v_last_names, 1))];

        -- 1. הכנת נתוני הרשמה ראליסטיים
        v_random_name := v_first_name || ' ' || v_last_name;
        
        -- שימוש בשם הפרטי (באותיות קטנות) + מספר אקראי למניעת כפילויות במייל
        v_random_email := lower(v_first_name) || floor(random() * 1000)::TEXT || '@jct-betting.com';
        v_random_balance := floor(random() * 1000 + 500);

        -- 2. הפעלת פרוצדורת הרישום
        CALL create_user(v_random_name, v_random_email, v_random_balance);

        -- 3. שליפת ה-ID של המשתמש שהרגע הוספנו לפי האימייל הייחודי
        SELECT user_id INTO v_new_user_id 
        FROM users 
        WHERE email = v_random_email;

        -- לולאה פנימית: ביצוע 2 הימורים לכל משתמש חדש
        FOR j IN 1..2 LOOP
            -- 4. בחירת משחק מונדיאל אקראי מתוך הצומת הגלובלי
            SELECT GlobalMatchID INTO v_random_match_id 
            FROM GLOBAL_MATCH 
            WHERE MatchSource = 'WorldCup' 
            ORDER BY random() LIMIT 1;

            -- 5. הגרלת סכום הימור חוקי ותוצאה מהמערך
            v_bet_amount := floor(random() * 150 + 50);
            v_random_prediction := v_predictions[1 + floor(random() * array_length(v_predictions, 1))];

            -- 6. הפעלת פרוצדורת ההימור
            CALL create_bet(v_new_user_id, v_random_match_id, v_bet_amount, v_random_prediction);
        END LOOP;
        
    END LOOP;

    RAISE NOTICE '--- Test Completed Successfully ---';
END;
$$;
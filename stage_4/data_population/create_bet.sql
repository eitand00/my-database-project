CREATE OR REPLACE PROCEDURE create_bet(
    p_user_id INT,
    p_global_match_id INT,
    p_amount NUMERIC,
    p_prediction VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_exists BOOLEAN;
    v_new_bet_id INT;
BEGIN
    -- 1. ולידציה של תוצאת ההימור
    IF p_prediction NOT IN ('Home', 'Draw', 'Away') THEN
        RAISE EXCEPTION 'Betting Failed: Invalid prediction syntax. Must be ''Home'', ''Draw'', or ''Away''. Received: "%"', p_prediction;
    END IF;

    -- 2. בדיקה האם המשחק קיים
    SELECT EXISTS(SELECT 1 FROM GLOBAL_MATCH WHERE GlobalMatchID = p_global_match_id) INTO v_match_exists;
    
    IF NOT v_match_exists THEN
        RAISE EXCEPTION 'Betting Failed: Match ID % does not exist.', p_global_match_id;
    END IF;

    -- 3. חישוב מזהה ההימור הבא הפנוי
    SELECT COALESCE(MAX(bet_id), 0) + 1 INTO v_new_bet_id FROM bets;

    -- 4. DML 1: קיזוז הכסף מיתרת המשתמש (עדכון)
    UPDATE users SET balance = balance - p_amount WHERE user_id = p_user_id;

    -- 5. DML 2: רישום ההימור (הכנסה) כולל תאריך ההימור האוטומטי
    INSERT INTO bets (
        bet_id, 
        user_id, 
        global_match_id, 
        bet_amount, 
        predicted_result, 
        bet_status, 
        bet_date
    )
    VALUES (
        v_new_bet_id, 
        p_user_id, 
        p_global_match_id, 
        p_amount, 
        p_prediction, 
        'Pending', 
        CURRENT_DATE -- מתעד את תאריך ביצוע ההימור
    );

    RAISE NOTICE 'System: Bet ID % placed successfully for user % on match % on %.', v_new_bet_id, p_user_id, p_global_match_id, CURRENT_DATE;

EXCEPTION
    -- תפיסת שגיאות וביטול העסקה לחלוטין
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction Aborted: %', SQLERRM;
        ROLLBACK;
END;
$$;
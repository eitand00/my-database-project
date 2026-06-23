CREATE OR REPLACE PROCEDURE crowd_wisdom()
LANGUAGE plpgsql AS $$
DECLARE
    v_bot_name VARCHAR := 'Crowd_Wisdom_Bot';
    v_bot_email VARCHAR := 'bot_' || floor(random() * 10000)::TEXT || '@jct-betting.com';
    v_bot_balance NUMERIC := 100000.0;
    v_bot_id INT;
    v_match_id INT;
    v_cur refcursor;
    v_name VARCHAR;
    v_amount NUMERIC;
    v_guess VARCHAR;
    v_status VARCHAR;
    v_home NUMERIC := 0; v_away NUMERIC := 0; v_draw NUMERIC := 0;
    v_chosen VARCHAR;
BEGIN
    CALL create_user(v_bot_name, v_bot_email, v_bot_balance);
    SELECT user_id INTO v_bot_id FROM users WHERE email = v_bot_email;
    SELECT global_match_id INTO v_match_id FROM bets
        WHERE global_match_id IS NOT NULL
        GROUP BY global_match_id HAVING COUNT(*) > 1 LIMIT 1;
    IF v_match_id IS NOT NULL THEN
        v_cur := Get_Match_Bettors_RefCursor(v_match_id);
        LOOP
            FETCH v_cur INTO v_name, v_amount, v_guess, v_status;
            EXIT WHEN NOT FOUND;
            IF v_guess = 'Home' THEN v_home := v_home + v_amount;
            ELSIF v_guess = 'Away' THEN v_away := v_away + v_amount;
            ELSIF v_guess = 'Draw' THEN v_draw := v_draw + v_amount;
            END IF;
        END LOOP;
        CLOSE v_cur;
        IF v_home >= v_away AND v_home >= v_draw THEN v_chosen := 'Home';
        ELSIF v_away >= v_home AND v_away >= v_draw THEN v_chosen := 'Away';
        ELSE v_chosen := 'Draw';
        END IF;
        CALL create_bet(v_bot_id, v_match_id, 1500.0, v_chosen);
    END IF;
END;
$$;

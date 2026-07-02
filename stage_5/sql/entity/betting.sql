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
    IF p_prediction NOT IN ('Home', 'Draw', 'Away') THEN
        RAISE EXCEPTION 'Betting Failed: Invalid prediction syntax. Must be ''Home'', ''Draw'', or ''Away''. Received: "%"', p_prediction;
    END IF;

    SELECT EXISTS(SELECT 1 FROM GLOBAL_MATCH WHERE GlobalMatchID = p_global_match_id) INTO v_match_exists;
    
    IF NOT v_match_exists THEN
        RAISE EXCEPTION 'Betting Failed: Match ID % does not exist.', p_global_match_id;
    END IF;

    SELECT COALESCE(MAX(bet_id), 0) + 1 INTO v_new_bet_id FROM bets;
    UPDATE users SET balance = balance - p_amount WHERE user_id = p_user_id;

    INSERT INTO bets (bet_id, user_id, global_match_id, bet_amount, predicted_result, bet_status, bet_date)
    VALUES (v_new_bet_id, p_user_id, p_global_match_id, p_amount, p_prediction, 'Pending', CURRENT_DATE);

    RAISE NOTICE 'System: Bet ID % placed successfully for user % on match % on %.', v_new_bet_id, p_user_id, p_global_match_id, CURRENT_DATE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction Aborted: %', SQLERRM;
        ROLLBACK;
END;
$$;

CREATE OR REPLACE PROCEDURE Mass_Update_Stage_Odds(p_stage VARCHAR, p_boost_factor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_id INT;
    v_counter INT := 0;
    v_match_cursor CURSOR FOR 
        SELECT gm.GlobalMatchID 
        FROM GLOBAL_MATCH gm
        JOIN MATCH m ON gm.WCMatchID = m.MatchID
        WHERE LOWER(m.Stage) = LOWER(p_stage) AND gm.MatchSource = 'WorldCup';
BEGIN
    OPEN v_match_cursor;
    
    LOOP
        FETCH v_match_cursor INTO v_match_id;
        EXIT WHEN NOT FOUND;

        UPDATE odds
        SET 
            home_win_odd = home_win_odd * p_boost_factor,
            away_win_odd = away_win_odd * p_boost_factor,
            draw_odd = draw_odd * p_boost_factor
        WHERE global_match_id = v_match_id;
        
        v_counter := v_counter + 1;
    END LOOP;
    
    CLOSE v_match_cursor;
    RAISE NOTICE 'Successfully boosted odds for % matches in stage %', v_counter, p_stage;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error encountered during mass update: %', SQLERRM;
        ROLLBACK;
END;
$$;

CREATE OR REPLACE PROCEDURE create_bet_print_payout()
LANGUAGE plpgsql AS $$
DECLARE
    v_user_id INT;
    v_match_id INT;
    v_amount NUMERIC;
    v_predictions TEXT[] := ARRAY['Home', 'Draw', 'Away'];
    v_prediction VARCHAR;
    v_bet_id INT;
    v_payout NUMERIC;
BEGIN
    FOR i IN 1..3 LOOP
        SELECT user_id INTO v_user_id FROM users ORDER BY random() LIMIT 1;
        SELECT global_match_id INTO v_match_id FROM odds ORDER BY random() LIMIT 1;
        v_amount := floor(random() * 150 + 50);
        v_prediction := v_predictions[1 + floor(random() * array_length(v_predictions, 1))];
        CALL create_bet(v_user_id, v_match_id, v_amount, v_prediction);
        SELECT MAX(bet_id) INTO v_bet_id FROM bets WHERE user_id = v_user_id;
        v_payout := Calculate_Potential_Payout(v_bet_id);
        RAISE NOTICE 'Bet %: payout=%', v_bet_id, v_payout;
    END LOOP;
END;
$$;

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

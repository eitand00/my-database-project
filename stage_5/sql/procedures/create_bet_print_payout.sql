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

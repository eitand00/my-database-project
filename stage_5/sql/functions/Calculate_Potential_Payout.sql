CREATE OR REPLACE FUNCTION Calculate_Potential_Payout(p_bet_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_bet_record bets%ROWTYPE;
    v_odds_record odds%ROWTYPE;
    v_expected_payout NUMERIC := 0;
BEGIN
    SELECT * INTO STRICT v_bet_record FROM bets WHERE bet_id = p_bet_id;
    SELECT * INTO STRICT v_odds_record FROM odds WHERE global_match_id = v_bet_record.global_match_id;

    IF v_bet_record.predicted_result = 'Home' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.home_win_odd;
    ELSIF v_bet_record.predicted_result = 'Away' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.away_win_odd;
    ELSIF v_bet_record.predicted_result = 'Draw' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.draw_odd;
    ELSE
        RAISE EXCEPTION 'Invalid predicted result format.';
    END IF;

    RETURN v_expected_payout;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Exception Caught: Bet ID % was not found.', p_bet_id;
        RETURN -1;
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
        RETURN -1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Get_Match_Bettors_RefCursor(p_global_match_id INT)
RETURNS refcursor AS $$
DECLARE
    v_ref_cur refcursor;
BEGIN
    OPEN v_ref_cur FOR  
        SELECT u.full_name, b.bet_amount, b.predicted_result, b.bet_status
        FROM bets b
        JOIN users u ON b.user_id = u.user_id
        WHERE b.global_match_id = p_global_match_id;
        
    RETURN v_ref_cur;
END;
$$ LANGUAGE plpgsql;

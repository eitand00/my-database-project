CREATE OR REPLACE FUNCTION Get_Match_Bettors(p_global_match_id INT)
RETURNS TABLE(full_name VARCHAR, amount NUMERIC, prediction VARCHAR, bet_status VARCHAR) AS $$
DECLARE
    v_cur refcursor;
    rec RECORD;
BEGIN
    v_cur := Get_Match_Bettors_RefCursor(p_global_match_id);
    LOOP
        FETCH v_cur INTO rec;
        EXIT WHEN NOT FOUND;
        full_name := rec.full_name;
        amount := rec.bet_amount;
        prediction := rec.predicted_result;
        bet_status := rec.bet_status;
        RETURN NEXT;
    END LOOP;
    CLOSE v_cur;
END;
$$ LANGUAGE plpgsql;

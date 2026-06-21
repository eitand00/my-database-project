-- א. פונקציית הטריגר
CREATE OR REPLACE FUNCTION trg_func_payout_on_win()
RETURNS TRIGGER AS $$
DECLARE
    v_odd NUMERIC;
    v_payout NUMERIC;
BEGIN
    -- בדיקה האם סטטוס ההימור עודכן הרגע ל-'Won' (ונוודא שלא היה 'Won' קודם כדי למנוע כפל תשלום)
    IF NEW.bet_status = 'Won' AND (OLD.bet_status IS DISTINCT FROM 'Won') THEN
        
        -- שליפת יחס הזכייה הרלוונטי מהמשחק שעליו המרו
        IF NEW.predicted_result = 'Home' THEN
            SELECT home_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Away' THEN
            SELECT away_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Draw' THEN
            SELECT draw_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        END IF;

        -- חישוב סכום הזכייה
        v_payout := NEW.bet_amount * v_odd;

        -- הוספת הכסף ליתרת המשתמש בטבלת המשתמשים
        UPDATE users 
        SET balance = balance + v_payout 
        WHERE user_id = NEW.user_id;
        
        RAISE NOTICE 'Trigger Executed: User % won bet %. Added % to balance.', NEW.user_id, NEW.bet_id, v_payout;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ב. חיבור הטריגר לטבלה
CREATE TRIGGER trg_payout_on_win
AFTER UPDATE OF bet_status ON bets
FOR EACH ROW
EXECUTE FUNCTION trg_func_payout_on_win();
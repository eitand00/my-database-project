-- ׳. ׳₪׳•׳ ׳§׳¦׳™׳™׳× ׳”׳˜׳¨׳™׳’׳¨
CREATE OR REPLACE FUNCTION trg_func_prevent_negative_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- ׳׳ ׳”׳™׳×׳¨׳” ׳”׳׳¢׳•׳“׳›׳ ׳× ׳§׳˜׳ ׳” ׳׳׳₪׳¡, ׳׳ ׳—׳ ׳• ׳¢׳•׳¦׳¨׳™׳ ׳׳× ׳”׳₪׳¢׳•׳׳”
    IF NEW.balance < 0 THEN
        RAISE EXCEPTION 'Transaction Denied: User % does not have enough funds. Balance cannot drop below 0 (Attempted balance: %)', NEW.user_id, NEW.balance;
    END IF;
    
    -- ׳׳ ׳”׳›׳ ׳×׳§׳™׳, ׳׳׳©׳¨׳™׳ ׳׳× ׳‘׳™׳¦׳•׳¢ ׳”׳©׳•׳¨׳” ׳”׳—׳“׳©׳”
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql;

-- ׳‘. ׳—׳™׳‘׳•׳¨ ׳”׳˜׳¨׳™׳’׳¨ ׳׳˜׳‘׳׳”
CREATE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE OF balance ON users
FOR EACH ROW
EXECUTE FUNCTION trg_func_prevent_negative_balance();
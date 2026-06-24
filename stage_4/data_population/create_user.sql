CREATE OR REPLACE PROCEDURE create_user(
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_initial_balance NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_user_id INT;
BEGIN
    -- ׳•׳׳™׳“׳¦׳™׳”
    IF p_full_name IS NULL OR length(trim(p_full_name)) = 0 THEN
        RAISE EXCEPTION 'Registration Failed: User name cannot be empty.';
    END IF;

    -- ׳—׳™׳©׳•׳‘ ׳”-ID ׳”׳‘׳ ׳”׳₪׳ ׳•׳™ ׳‘׳׳¢׳¨׳›׳×
    SELECT COALESCE(MAX(user_id), 0) + 1 INTO v_new_user_id FROM users;

    -- DML: ׳”׳•׳¡׳₪׳× ׳”׳׳©׳×׳׳© ׳¢׳ ׳›׳ ׳©׳“׳•׳× ׳”׳—׳•׳‘׳”
    -- ׳”׳¢׳¨׳”: ׳׳ ׳©׳׳•׳× ׳”׳¢׳׳•׳“׳•׳× ׳׳¦׳׳›׳ ׳§׳¦׳× ׳©׳•׳ ׳™׳ (׳׳׳©׳ status ׳‘׳׳§׳•׳ account_status), ׳×׳©׳ ׳” ׳›׳׳.
    INSERT INTO users (
        user_id, 
        full_name, 
        email, 
        balance, 
        registration_date, 
        account_status
    )
    VALUES (
        v_new_user_id, 
        p_full_name, 
        p_email, 
        p_initial_balance, 
        CURRENT_DATE,     -- ׳׳•׳§׳— ׳׳•׳˜׳•׳׳˜׳™׳× ׳׳× ׳”׳×׳׳¨׳™׳ ׳©׳ ׳”׳™׳•׳
        'Active'          -- ׳¡׳˜׳˜׳•׳¡ ׳‘׳¨׳™׳¨׳× ׳׳—׳“׳ ׳׳׳©׳×׳׳© ׳—׳“׳©
    );

    RAISE NOTICE 'System: User "%" registered successfully with ID %, Date: %, Status: Active.', p_full_name, v_new_user_id, CURRENT_DATE;
END;
$$;
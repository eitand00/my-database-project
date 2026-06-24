ALTER TABLE MATCH_EVENT 
ALTER COLUMN Minute TYPE integer 
USING (
    -- ׳׳•׳§׳— ׳׳× ׳”׳—׳׳§ ׳©׳׳₪׳ ׳™ ׳”׳₪׳׳•׳¡ (׳׳• ׳׳× ׳›׳ ׳”׳׳¡׳₪׳¨ ׳׳ ׳׳™׳ ׳₪׳׳•׳¡)
    split_part(REPLACE(Minute, '''', ''), '+', 1)::integer + 
    -- ׳׳•׳§׳— ׳׳× ׳”׳—׳׳§ ׳©׳׳—׳¨׳™ ׳”׳₪׳׳•׳¡. ׳׳ ׳׳™׳ ׳—׳׳§ ׳›׳–׳”, ׳”׳•׳ ׳™׳—׳‘׳¨ 0
    COALESCE(NULLIF(split_part(REPLACE(Minute, '''', ''), '+', 2), ''), '0')::integer
);


-- ׳׳™׳׳•׳¥ 1: ׳§׳™׳‘׳•׳׳× ׳׳¦׳˜׳“׳™׳•׳ ׳—׳™׳™׳‘׳× ׳׳”׳™׳•׳× ׳׳¡׳₪׳¨ ׳—׳™׳•׳‘׳™ ׳’׳“׳•׳ ׳׳׳₪׳¡.
-- ׳׳ ׳”׳’׳™׳•׳ ׳™ ׳©׳™׳© ׳׳¦׳˜׳“׳™׳•׳ ׳¢׳ ׳׳™׳ ׳•׳¡ ׳׳•׳©׳‘׳™׳ ׳׳• 0 ׳׳•׳©׳‘׳™׳.
-- ׳׳™׳׳•׳¥ 1 ׳”׳׳×׳•׳§׳:
ALTER TABLE STADIUM
ADD CONSTRAINT chk_stadium_capacity CHECK (Capacity::integer > 0);


-- ׳׳™׳׳•׳¥ 2: ׳“׳§׳× ׳׳™׳¨׳•׳¢ ׳‘׳׳©׳—׳§ ׳—׳™׳™׳‘׳× ׳׳”׳™׳•׳× ׳‘׳™׳ 1 ׳-130.
-- (׳׳©׳—׳§ ׳¨׳’׳™׳ 90 ׳“׳§׳•׳× + ׳”׳׳¨׳›׳” 120 + ׳×׳•׳¡׳₪׳•׳× ׳–׳׳, ׳׳›׳ 130 ׳”׳•׳ ׳’׳‘׳•׳ ׳¢׳׳™׳•׳ ׳”׳’׳™׳•׳ ׳™).
ALTER TABLE MATCH_EVENT
ADD CONSTRAINT chk_event_minute CHECK (Minute::integer > 0 AND Minute::integer <= 130);

-- ׳׳™׳׳•׳¥ 3: ׳”׳’׳‘׳׳× ׳©׳׳‘׳™ ׳”׳˜׳•׳¨׳ ׳™׳¨ ׳׳¢׳¨׳›׳™׳ ׳׳•׳’׳“׳¨׳™׳ ׳׳¨׳׳©.
-- ׳׳•׳ ׳¢ ׳˜׳¢׳•׳™׳•׳× ׳”׳§׳׳“׳” ׳›׳׳• 'Gmar' ׳‘׳׳§׳•׳ 'Final'.
ALTER TABLE MATCH
ADD CONSTRAINT chk_match_stage CHECK (Stage IN ('Group Stage', 'Round of 16', 'Quarter-Final', 'Semi-Final', 'Third Place', 'Final'));
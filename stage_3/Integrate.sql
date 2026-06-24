-- ====================================================================
-- ׳§׳•׳‘׳¥ ׳׳™׳ ׳˜׳’׳¨׳¦׳™׳”: Integrate.sql
-- ׳׳˜׳¨׳× ׳”׳§׳•׳‘׳¥: ׳—׳™׳‘׳•׳¨ ׳׳¢׳¨׳›׳× ׳¡׳˜׳˜׳™׳¡׳˜׳™׳§׳•׳× ׳”׳׳•׳ ׳“׳™׳׳ ׳׳׳¢׳¨׳›׳× ׳”׳”׳™׳׳•׳¨׳™׳
-- ׳©׳™׳˜׳× ׳”׳׳™׳ ׳˜׳’׳¨׳¦׳™׳”: ׳™׳¦׳™׳¨׳× ׳˜׳‘׳׳×-׳¢׳ (Super-type) ׳׳¨׳›׳–׳™׳× ׳׳׳©׳—׳§׳™׳
-- ====================================================================

-- ---------------------------------------------------------
-- ׳©׳׳‘ 1: ׳™׳¦׳™׳¨׳× ׳˜׳‘׳׳× ׳”׳׳™׳₪׳•׳™ ׳”׳׳¨׳›׳–׳™׳× (Super-type)
-- ---------------------------------------------------------
CREATE TABLE GLOBAL_MATCH (
    GlobalMatchID SERIAL PRIMARY KEY,
    MatchSource VARCHAR(20) NOT NULL, -- ׳™׳›׳™׳ 'WorldCup' ׳׳• 'Betting'
    WCMatchID VARCHAR(50),
    BettingMatchID INT,
    
    -- ׳׳₪׳×׳—׳•׳× ׳–׳¨׳™׳ ׳׳˜׳‘׳׳׳•׳× ׳”׳׳§׳•׳¨׳™׳•׳×
    CONSTRAINT fk_global_wc FOREIGN KEY (WCMatchID) REFERENCES MATCH(MatchID),
    CONSTRAINT fk_global_betting FOREIGN KEY (BettingMatchID) REFERENCES matches(match_id),
    
    -- ׳”׳‘׳˜׳—׳× ׳©׳׳׳•׳× ׳ ׳×׳•׳ ׳™׳: ׳›׳ ׳©׳•׳¨׳” ׳׳׳₪׳” ׳‘׳“׳™׳•׳§ ׳׳׳©׳—׳§ ׳׳—׳“, ׳©׳׳ ׳• ׳׳• ׳©׳׳”׳
    CONSTRAINT chk_exclusive_match CHECK (
        (WCMatchID IS NOT NULL AND BettingMatchID IS NULL) OR 
        (WCMatchID IS NULL AND BettingMatchID IS NOT NULL)
    )
);

-- ---------------------------------------------------------
-- ׳©׳׳‘ 2: ׳׳›׳׳•׳¡ ׳”׳˜׳‘׳׳” ׳”׳׳¨׳›׳–׳™׳× ׳‘׳›׳ ׳”׳׳©׳—׳§׳™׳ ׳׳©׳×׳™ ׳”׳׳¢׳¨׳›׳•׳×
-- ---------------------------------------------------------
-- ׳™׳™׳‘׳•׳ ׳׳©׳—׳§׳™ ׳”׳׳•׳ ׳“׳™׳׳ ׳©׳׳ ׳•:
INSERT INTO GLOBAL_MATCH (MatchSource, WCMatchID)
SELECT 'WorldCup', MatchID FROM MATCH;

-- ׳™׳™׳‘׳•׳ ׳”׳׳©׳—׳§׳™׳ ׳”׳¨׳’׳™׳׳™׳ ׳׳”׳’׳™׳‘׳•׳™ ׳©׳ ׳׳¢׳¨׳›׳× ׳”׳”׳™׳׳•׳¨׳™׳:
INSERT INTO GLOBAL_MATCH (MatchSource, BettingMatchID)
SELECT 'Betting', match_id FROM matches;

-- ---------------------------------------------------------
-- ׳©׳׳‘ 3: ׳—׳™׳‘׳•׳¨ ׳”׳׳¢׳¨׳›׳× ׳”׳₪׳™׳ ׳ ׳¡׳™׳× ׳׳˜׳‘׳׳” ׳”׳׳¨׳›׳–׳™׳× ׳”׳—׳“׳©׳”
-- ---------------------------------------------------------
-- ׳”׳•׳¡׳₪׳× ׳¢׳׳•׳“׳•׳× ׳׳˜׳‘׳׳׳•׳× ׳”׳”׳™׳׳•׳¨׳™׳ ׳•׳™׳—׳¡׳™ ׳”׳–׳›׳™׳™׳”
ALTER TABLE bets ADD COLUMN global_match_id INT;
ALTER TABLE odds ADD COLUMN global_match_id INT;

-- ׳”׳’׳“׳¨׳×׳ ׳›׳׳₪׳×׳—׳•׳× ׳–׳¨׳™׳ ׳׳˜׳‘׳׳” ׳”׳—׳“׳©׳”
ALTER TABLE bets ADD CONSTRAINT fk_bets_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);
ALTER TABLE odds ADD CONSTRAINT fk_odds_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);

-- ---------------------------------------------------------
-- ׳©׳׳‘ 4: ׳”׳¡׳‘׳× ׳”׳ ׳×׳•׳ ׳™׳ (Data Migration) ׳©׳ ׳”׳’׳™׳‘׳•׳™ ׳”׳™׳©׳
-- ---------------------------------------------------------
-- ׳¢׳“׳›׳•׳ ׳”׳”׳™׳׳•׳¨׳™׳ ׳”׳§׳™׳™׳׳™׳ ׳›׳ ׳©׳™׳¦׳‘׳™׳¢׳• ׳-ID ׳”׳’׳׳•׳‘׳׳™ ׳‘׳׳§׳•׳ ׳-ID ׳”׳™׳©׳ ׳©׳׳”׳
UPDATE bets
SET global_match_id = (
    SELECT GlobalMatchID 
    FROM GLOBAL_MATCH 
    WHERE BettingMatchID = bets.match_id
);

-- ׳¢׳“׳›׳•׳ ׳™׳—׳¡׳™ ׳”׳–׳›׳™׳™׳” ׳”׳§׳™׳™׳׳™׳ ׳›׳ ׳©׳™׳¦׳‘׳™׳¢׳• ׳-ID ׳”׳’׳׳•׳‘׳׳™
UPDATE odds
SET global_match_id = (
    SELECT GlobalMatchID 
    FROM GLOBAL_MATCH 
    WHERE BettingMatchID = odds.match_id
);

-- ---------------------------------------------------------
-- ׳©׳׳‘ 5 (׳”׳¡׳•׳₪׳™): ׳”׳¡׳‘׳× ׳ ׳×׳•׳ ׳™׳ ׳•׳©׳™׳“׳•׳ 1:1 (Data Migration & Pairing)
-- ׳׳¡׳™׳‘׳™׳ 10 ׳׳©׳—׳§׳™ ׳”׳™׳׳•׳¨׳™׳ ׳׳ 10 ׳׳©׳—׳§׳™ ׳׳•׳ ׳“׳™׳׳ ׳©׳•׳ ׳™׳, ׳›׳•׳׳ ׳›׳ ׳”׳ ׳×׳•׳ ׳™׳ ׳”׳ ׳׳•׳•׳™׳
-- ---------------------------------------------------------
WITH BettingMatchesToUpdate AS (
    -- ׳©׳׳™׳₪׳× ׳›׳ ׳׳–׳”׳™ ׳”׳׳©׳—׳§׳™׳ ׳׳”׳׳¢׳¨׳›׳× ׳”׳™׳©׳ ׳” ׳©׳™׳© ׳׳”׳ ׳”׳™׳׳•׳¨׳™׳ ׳•׳™׳—׳¡׳™ ׳–׳›׳™׳™׳”, ׳•׳׳¡׳₪׳•׳¨׳ 1 ׳¢׳“ N
    SELECT gm.GlobalMatchID, ROW_NUMBER() OVER () as rn
    FROM GLOBAL_MATCH gm
    -- ׳׳•׳•׳“׳׳™׳ ׳©׳‘׳•׳—׳¨׳™׳ ׳¨׳§ ׳׳©׳—׳§׳™׳ ׳©׳™׳© ׳׳”׳ ׳’׳ ׳”׳™׳׳•׳¨׳™׳ ׳•׳’׳ ׳™׳—׳¡׳™ ׳–׳›׳™׳™׳”
    WHERE gm.MatchSource = 'Betting'
      AND EXISTS (SELECT 1 FROM bets b WHERE b.global_match_id = gm.GlobalMatchID)
      AND EXISTS (SELECT 1 FROM odds o WHERE o.global_match_id = gm.GlobalMatchID)
),
RandomWCMatches AS (
    -- ׳©׳׳™׳₪׳× 10 ׳׳–׳”׳™ ׳׳©׳—׳§׳™ ׳׳•׳ ׳“׳™׳׳ ׳׳§׳¨׳׳™׳™׳, ׳•׳׳¡׳₪׳•׳¨׳ 1 ׳¢׳“ 10
    SELECT MatchID, ROW_NUMBER() OVER () as rn
    FROM MATCH
    ORDER BY random()
    LIMIT 10
)
-- ׳‘׳™׳¦׳•׳¢ ׳”׳¢׳“׳›׳•׳ ׳¢׳ ׳™׳“׳™ ׳©׳™׳“׳•׳ ׳”׳׳¡׳₪׳¨׳™׳ (rn)
UPDATE GLOBAL_MATCH gm
SET 
    MatchSource = 'WorldCup',
    WCMatchID = rwc.MatchID,
    BettingMatchID = NULL
FROM BettingMatchesToUpdate btu
JOIN RandomWCMatches rwc ON btu.rn = rwc.rn
WHERE gm.GlobalMatchID = btu.GlobalMatchID;

-- ====================================================================
-- ׳©׳׳‘ ׳ ׳™׳§׳•׳™ ׳•׳׳¨׳’׳•׳ ׳׳—׳“׳©: ׳”׳¡׳¨׳× ׳”׳§׳©׳¨׳™׳ ׳”׳™׳©׳ ׳™׳
-- ====================================================================

-- 1. ׳׳—׳™׳§׳× ׳¢׳׳•׳“׳× ׳”׳׳©׳—׳§ ׳”׳™׳©׳ ׳” ׳׳˜׳‘׳׳× ׳”׳”׳™׳׳•׳¨׳™׳ (׳׳•׳—׳§ ׳׳•׳˜׳•׳׳˜׳™׳× ׳׳× ׳”-FK ׳”׳™׳©׳)
ALTER TABLE bets DROP COLUMN match_id;

-- 2. ׳׳—׳™׳§׳× ׳¢׳׳•׳“׳× ׳”׳׳©׳—׳§ ׳”׳™׳©׳ ׳” ׳׳˜׳‘׳׳× ׳™׳—׳¡׳™ ׳”׳–׳›׳™׳™׳”
ALTER TABLE odds DROP COLUMN match_id;

-- 3. ׳”׳—׳׳× ׳׳™׳׳•׳¥ NOT NULL ׳¢׳ ׳”׳¢׳׳•׳“׳” ׳”׳’׳׳•׳‘׳׳™׳× ׳”׳—׳“׳©׳” (׳—׳•׳‘׳” ׳©׳›׳ ׳”׳™׳׳•׳¨/׳™׳—׳¡ ׳™׳¦׳‘׳™׳¢ ׳׳¦׳•׳׳× ׳”׳׳¨׳›׳–׳™)
ALTER TABLE bets ALTER COLUMN global_match_id SET NOT NULL;
ALTER TABLE odds ALTER COLUMN global_match_id SET NOT NULL;
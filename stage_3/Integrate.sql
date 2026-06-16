-- ====================================================================
-- קובץ אינטגרציה: Integrate.sql
-- מטרת הקובץ: חיבור מערכת סטטיסטיקות המונדיאל למערכת ההימורים
-- שיטת האינטגרציה: יצירת טבלת-על (Super-type) מרכזית למשחקים
-- ====================================================================

-- ---------------------------------------------------------
-- שלב 1: יצירת טבלת המיפוי המרכזית (Super-type)
-- ---------------------------------------------------------
CREATE TABLE GLOBAL_MATCH (
    GlobalMatchID SERIAL PRIMARY KEY,
    MatchSource VARCHAR(20) NOT NULL, -- יכיל 'WorldCup' או 'Betting'
    WCMatchID VARCHAR(50),
    BettingMatchID INT,
    
    -- מפתחות זרים לטבלאות המקוריות
    CONSTRAINT fk_global_wc FOREIGN KEY (WCMatchID) REFERENCES MATCH(MatchID),
    CONSTRAINT fk_global_betting FOREIGN KEY (BettingMatchID) REFERENCES matches(match_id),
    
    -- הבטחת שלמות נתונים: כל שורה ממפה בדיוק למשחק אחד, שלנו או שלהם
    CONSTRAINT chk_exclusive_match CHECK (
        (WCMatchID IS NOT NULL AND BettingMatchID IS NULL) OR 
        (WCMatchID IS NULL AND BettingMatchID IS NOT NULL)
    )
);

-- ---------------------------------------------------------
-- שלב 2: אכלוס הטבלה המרכזית בכל המשחקים משתי המערכות
-- ---------------------------------------------------------
-- ייבוא משחקי המונדיאל שלנו:
INSERT INTO GLOBAL_MATCH (MatchSource, WCMatchID)
SELECT 'WorldCup', MatchID FROM MATCH;

-- ייבוא המשחקים הרגילים מהגיבוי של מערכת ההימורים:
INSERT INTO GLOBAL_MATCH (MatchSource, BettingMatchID)
SELECT 'Betting', match_id FROM matches;

-- ---------------------------------------------------------
-- שלב 3: חיבור המערכת הפיננסית לטבלה המרכזית החדשה
-- ---------------------------------------------------------
-- הוספת עמודות לטבלאות ההימורים ויחסי הזכייה
ALTER TABLE bets ADD COLUMN global_match_id INT;
ALTER TABLE odds ADD COLUMN global_match_id INT;

-- הגדרתן כמפתחות זרים לטבלה החדשה
ALTER TABLE bets ADD CONSTRAINT fk_bets_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);
ALTER TABLE odds ADD CONSTRAINT fk_odds_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);

-- ---------------------------------------------------------
-- שלב 4: הסבת הנתונים (Data Migration) של הגיבוי הישן
-- ---------------------------------------------------------
-- עדכון ההימורים הקיימים כך שיצביעו ל-ID הגלובלי במקום ל-ID הישן שלהם
UPDATE bets
SET global_match_id = (
    SELECT GlobalMatchID 
    FROM GLOBAL_MATCH 
    WHERE BettingMatchID = bets.match_id
);

-- עדכון יחסי הזכייה הקיימים כך שיצביעו ל-ID הגלובלי
UPDATE odds
SET global_match_id = (
    SELECT GlobalMatchID 
    FROM GLOBAL_MATCH 
    WHERE BettingMatchID = odds.match_id
);

-- ---------------------------------------------------------
-- שלב 5 (הסופי): הסבת נתונים ושידוך 1:1 (Data Migration & Pairing)
-- מסיבים 10 משחקי הימורים אל 10 משחקי מונדיאל שונים, כולל כל הנתונים הנלווים
-- ---------------------------------------------------------
WITH BettingMatchesToUpdate AS (
    -- שליפת כל מזהי המשחקים מהמערכת הישנה שיש להם הימורים ויחסי זכייה, ומספורם 1 עד N
    SELECT gm.GlobalMatchID, ROW_NUMBER() OVER () as rn
    FROM GLOBAL_MATCH gm
    -- מוודאים שבוחרים רק משחקים שיש להם גם הימורים וגם יחסי זכייה
    WHERE gm.MatchSource = 'Betting'
      AND EXISTS (SELECT 1 FROM bets b WHERE b.global_match_id = gm.GlobalMatchID)
      AND EXISTS (SELECT 1 FROM odds o WHERE o.global_match_id = gm.GlobalMatchID)
),
RandomWCMatches AS (
    -- שליפת 10 מזהי משחקי מונדיאל אקראיים, ומספורם 1 עד 10
    SELECT MatchID, ROW_NUMBER() OVER () as rn
    FROM MATCH
    ORDER BY random()
    LIMIT 10
)
-- ביצוע העדכון על ידי שידוך המספרים (rn)
UPDATE GLOBAL_MATCH gm
SET 
    MatchSource = 'WorldCup',
    WCMatchID = rwc.MatchID,
    BettingMatchID = NULL
FROM BettingMatchesToUpdate btu
JOIN RandomWCMatches rwc ON btu.rn = rwc.rn
WHERE gm.GlobalMatchID = btu.GlobalMatchID;

-- ====================================================================
-- שלב ניקוי וארגון מחדש: הסרת הקשרים הישנים
-- ====================================================================

-- 1. מחיקת עמודת המשחק הישנה מטבלת ההימורים (מוחק אוטומטית את ה-FK הישן)
ALTER TABLE bets DROP COLUMN match_id;

-- 2. מחיקת עמודת המשחק הישנה מטבלת יחסי הזכייה
ALTER TABLE odds DROP COLUMN match_id;

-- 3. החלת אילוץ NOT NULL על העמודה הגלובלית החדשה (חובה שכל הימור/יחס יצביע לצומת המרכזי)
ALTER TABLE bets ALTER COLUMN global_match_id SET NOT NULL;
ALTER TABLE odds ALTER COLUMN global_match_id SET NOT NULL;
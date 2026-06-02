ALTER TABLE MATCH_EVENT 
ALTER COLUMN Minute TYPE integer 
USING (
    -- לוקח את החלק שלפני הפלוס (או את כל המספר אם אין פלוס)
    split_part(REPLACE(Minute, '''', ''), '+', 1)::integer + 
    -- לוקח את החלק שאחרי הפלוס. אם אין חלק כזה, הוא יחבר 0
    COALESCE(NULLIF(split_part(REPLACE(Minute, '''', ''), '+', 2), ''), '0')::integer
);


-- אילוץ 1: קיבולת אצטדיון חייבת להיות מספר חיובי גדול מאפס.
-- לא הגיוני שיש אצטדיון עם מינוס מושבים או 0 מושבים.
-- אילוץ 1 המתוקן:
ALTER TABLE STADIUM
ADD CONSTRAINT chk_stadium_capacity CHECK (Capacity::integer > 0);


-- אילוץ 2: דקת אירוע במשחק חייבת להיות בין 1 ל-130.
-- (משחק רגיל 90 דקות + הארכה 120 + תוספות זמן, לכן 130 הוא גבול עליון הגיוני).
ALTER TABLE MATCH_EVENT
ADD CONSTRAINT chk_event_minute CHECK (Minute::integer > 0 AND Minute::integer <= 130);

-- אילוץ 3: הגבלת שלבי הטורניר לערכים מוגדרים מראש.
-- מונע טעויות הקלדה כמו 'Gmar' במקום 'Final'.
ALTER TABLE MATCH
ADD CONSTRAINT chk_match_stage CHECK (Stage IN ('Group Stage', 'Round of 16', 'Quarter-Final', 'Semi-Final', 'Third Place', 'Final'));
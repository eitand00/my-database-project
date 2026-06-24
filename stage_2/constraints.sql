ALTER TABLE MATCH_EVENT 
ALTER COLUMN Minute TYPE integer 
USING (
    split_part(REPLACE(Minute, '''', ''), '+', 1)::integer + 
    COALESCE(NULLIF(split_part(REPLACE(Minute, '''', ''), '+', 2), ''), '0')::integer
);


ALTER TABLE STADIUM
ADD CONSTRAINT chk_stadium_capacity CHECK (Capacity::integer > 0);


ALTER TABLE MATCH_EVENT
ADD CONSTRAINT chk_event_minute CHECK (Minute::integer > 0 AND Minute::integer <= 130);

ALTER TABLE MATCH
ADD CONSTRAINT chk_match_stage CHECK (Stage IN ('group stage', 'second group stage' , 'round of 16', 'quarter-finals', 'semi-finals', 'third-place match', 'final'));
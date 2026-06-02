-- תיקון אותיות קטנות וניסוחH SET Stage = 'Group Stage' WHERE Stage = 'group stage';
UPDATE MATCH SET Stage = 'Round of 16' WHERE Stage = 'round of 16';
UPDATE MATCH SET Stage = 'Quarter-Final' WHERE Stage = 'quarter-finals';
UPDATE MATים שונים
UPDATE MATCCH SET Stage = 'Semi-Final' WHERE Stage = 'semi-finals';
UPDATE MATCH SET Stage = 'Third Place' WHERE Stage = 'third-place match';
UPDATE MATCH SET Stage = 'Final' WHERE Stage = 'final';

-- טיפול בשלב הבתים השני (איחוד לשלב בתים רגיל)
UPDATE MATCH SET Stage = 'Group Stage' WHERE Stage = 'second group stage';
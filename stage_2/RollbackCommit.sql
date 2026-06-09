--ROLLLBACK EXAMPLE
BEGIN;

UPDATE stadium 
SET name = 'Temporary Name Test' 
WHERE stadiumid = 'S-101';

SELECT stadiumid, name FROM stadium WHERE stadiumid = 'S-101';

ROLLBACK;

SELECT stadiumid, name FROM stadium WHERE stadiumid = 'S-101';

--COMMIT EXAMPLE
BEGIN;

UPDATE stadium 
SET capacity = CAST(capacity AS INTEGER) + 100 
WHERE stadiumid = 'S-102';

SELECT stadiumid, name, capacity FROM stadium WHERE stadiumid = 'S-102';

COMMIT;

SELECT stadiumid, name, capacity FROM stadium WHERE stadiumid = 'S-102';
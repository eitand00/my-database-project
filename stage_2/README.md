-------------------------------------------------------------------------------------------------------------------------------------------------------------------
דו"ח פרויקט מונדיאל - שלב א'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
חלק א': מוטיבציה ותועלת של הוספת אילוצים (Constraints)
המוטיבציה המרכזית מאחורי הוספת האילוצים היא הבטחת שלמות ואמינות הנתונים (Data Integrity). מאחר שחלק מהעמודות במערכת שלנו מיובאות מקובצי מקור והוגדרו כטקסט (TEXT או VARCHAR), עולה סכנה שיוזנו נתונים שאינם תואמים את ההיגיון העסקי והמספרי. האילוצים שהוספנו מבצעים "בקרת איכות" אוטומטית ברמת מסד הנתונים ומונעים הזנת נתוני-זבל כתוצאה מטעויות אנוש או באגים.

אילוץ תקינות דקות אירוע (chk_eventtype_not_empty): מונע הזנת רשומות בהן סוג האירוע נותר ריק. האילוץ מוודא באמצעות פונקציית LENGTH כי אורך הטקסט בעמודה גדול מאפס. התועלת העסקית היא מניעת יצירת אירועים חסרי משמעות, מה שמבטיח שדוחות הסטטיסטיקה של הטורניר יתבססו על נתונים מלאים ולא יכילו רשומות "רפאים" שעלולות לשבש את החישובים.

אילוץ קיבולת אצטדיון חיובית (chk_positive_capacity): מונע מצב שבו מוזנת בטעות קיבולת שלילית. מכיוון שהעמודה הוגדרה כטקסט, השתמשנו בפונקציית CAST(capacity AS INTEGER) כדי לאלץ את המערכת להתייחס לערך כמספר שלם לצורך ההשוואה המתמטית. הדבר חוסם הזנת ערכים שגויים שעלולים לשבש אלגוריתמים של חישובי מכירת כרטיסים, הכנסות או ממוצעי קהל למשחק.

אילוץ מניעת כפילות קבוצות (chk_different_teams): מיישם לוגיקה עסקית בסיסית של עולם הספורט ישירות ברמת ה-DB – נבחרת אינה יכולה לשחק נגד עצמה. זה מונע יצירת רשומות משחק פיקטיביות (למשל ARG נגד ARG) שישבשו את הסטטיסטיקה.

חלק ב': מוטיבציה ותועלת של הוספת אינדקסים (Indexes)
המוטיבציה בהוספת אינדקסים היא ייעול ביצועים (Performance Tuning), הפחתת עומס ה-I/O על השרת, וצמצום משמעותי של זמני הריצה (Execution Time). האינדקסים משנים את אופן הסריקה מחיפוש טורי (Sequential Scan) לחיפוש מהיר ויעיל באמצעות עץ B-Tree.

אינדקס על eventtype: טבלת match_event היא הטבלה העמוסה ביותר במערכת (מכילה אלפי אירועים). רוב השאילתות שואבות ספציפית "גולים" או "כרטיסים". האינדקס חוסך למנוע ה-SQL את הצורך לקרוא אירועים לא רלוונטיים, ומאיץ את הסינון.

אינדקס על matchdate: שאילתות רבות מבוססות על חתך זמנים (החל מחיפושי משחקים ב-2018 ועד חיפושים לפי חודשים ושלבים). בניית האינדקס ממיינת את התאריכים מאחורי הקלעים ומאיצה את משיכת המידע.

אינדקס על teamcode בטבלת השחקנים: כשיש מאות שחקנים במערכת, המשתמש (לרוב) ירצה לסנן שחקנים לפי נבחרת מסוימת. האינדקס מחבר לוגית את שחקני אותה נבחרת יחד, מה שמאיץ פקודות JOIN עתידיות ומפחית את זמן השליפה לסדר גודל של חלקיקי שנייה, כפי שהוכח בבדיקות ה-EXPLAIN ANALYZE.




-------------------------------------------------------------------------------------------------------------------------------------------------------------------
דו"ח פרויקט מונדיאל - שלב ב'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

תיאור: שליפת כל המשחקים שבהם הובקעו יותר מ-3 שערים בשנת 2018. השאילתה מציגה את פרטי המשחק, הנבחרות המשתתפות, האצטדיון וסיכום כמות השערים הכוללת.


```WITH GoalCounts AS (
    SELECT 
        MatchID, 
        COUNT(MatchEventID) AS TotalGoals
    FROM MATCH_EVENT
    WHERE EventType = 'Goal'
    GROUP BY MatchID
    HAVING COUNT(MatchEventID) > 3
)
SELECT 
    m.MatchID,
    EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDayAndMonth,
    EXTRACT(YEAR FROM m.MatchDate) AS MatchYear,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    gc.TotalGoals
FROM MATCH m
JOIN GoalCounts gc ON m.MatchID = gc.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
ORDER BY gc.TotalGoals DESC;


SELECT 
    m.MatchID,
    EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDayAndMonth,
    EXTRACT(YEAR FROM m.MatchDate) AS MatchYear,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS TotalGoals
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') > 3
ORDER BY TotalGoals DESC;
```


<img width="1150" height="738" alt="image" src="https://github.com/user-attachments/assets/5cbf6023-9886-4cd1-bba3-d11988ffbd58" />


ההבדל: הגרסה היעילה משתמשת ב-CTE (WITH GoalCounts), שמחשב את סך השערים למשחק פעם אחת בלבד ושומר את התוצאה בטבלה זמנית. הגרסה הלא-יעילה מריצה SELECT COUNT פנימי עבור כל שורה בטבלת המשחקים הראשית.

מדוע היעילה טובה יותר: בשיטה היעילה (CTE), המערכת סורקת את טבלת האירועים פעם אחת ומבצעת Group By. בשיטה השנייה, עבור כל משחק (נניח 64 משחקים), המערכת נאלצת "לקפוץ" לטבלת האירועים ולסרוק אותה מחדש, מה שיוצר תקורה (Overhead) עצומה על המעבד והדיסק.




תיאור: זיהוי אצטדיונים גדולים בעלי תכולה של 60,000 צופים ומעלה, אשר אירחו לפחות משחק אחד שבו נשלף כרטיס אדום.

```
SELECT DISTINCT
    s.Name AS StadiumName,
    s.City AS StadiumCity,
    s.Capacity,
    m.MatchDate,
    m.Stage,
    m.Tournament
FROM STADIUM s
JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
  AND EXISTS (
      SELECT 1 
      FROM MATCH_EVENT me 
      WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card'
  );


SELECT DISTINCT
    s.Name AS StadiumName,
    s.City AS StadiumCity,
    s.Capacity,
    m.MatchDate,
    m.Stage,
    m.Tournament
FROM STADIUM s
JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
  AND m.MatchID IN (
      SELECT MatchID 
      FROM MATCH_EVENT 
      WHERE EventType = 'Red Card'
  );
```


<img width="996" height="666" alt="image" src="https://github.com/user-attachments/assets/ea1572c7-0571-4da2-af94-6ed2f2a69619" />

ההבדל: הגרסה היעילה משתמשת ב-EXISTS, בעוד הגרסה הלא-יעילה משתמשת ב-IN.

מדוע היעילה טובה יותר: מפעיל EXISTS הוא מסוג "קצר-סגור" (Short-circuit): ברגע שהוא מוצא את הכרטיס האדום הראשון לאותו משחק, הוא עוצר ולא ממשיך לחפש. לעומתו, IN דורש ממסד הנתונים ליצור רשימה של כל המזהים שעונים על התנאי לפני שהוא משווה, דבר שדורש יותר זיכרון וזמן ריצה ככל שטבלת האירועים גדלה.




תיאור: הפקת דוח המציג שופטים שניהלו משחקים בטורניר 2018, תוך התמקדות במשחקים "אגרסיביים" בהם נשלפו יותר מ-4 כרטיסים צהובים.


```
SELECT 
    p.GivenName || ' ' || p.FamilyName AS RefereeName,
    r.Country AS RefereeCountry,
    m.Stage,
    EXTRACT(YEAR FROM m.MatchDate) AS TournamentYear,
    COUNT(me.MatchEventID) AS YellowCardsGiven
FROM PERSON p
JOIN REFEREE r ON p.ID = r.ID
JOIN MATCH m ON r.ID = m.RefereeID
JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
WHERE me.EventType = 'Yellow Card' 
  AND EXTRACT(YEAR FROM m.MatchDate) = 2018
GROUP BY p.ID, p.GivenName, p.FamilyName, r.Country, m.MatchID, m.Stage, m.MatchDate
HAVING COUNT(me.MatchEventID) > 4
ORDER BY YellowCardsGiven DESC;


SELECT 
    p.GivenName || ' ' || p.FamilyName AS RefereeName,
    r.Country AS RefereeCountry,
    m.Stage,
    EXTRACT(YEAR FROM m.MatchDate) AS TournamentYear,
    (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Yellow Card') AS YellowCardsGiven
FROM PERSON p
JOIN REFEREE r ON p.ID = r.ID
JOIN MATCH m ON r.ID = m.RefereeID
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Yellow Card') > 4
ORDER BY YellowCardsGiven DESC;
```


<img width="1039" height="687" alt="image" src="https://github.com/user-attachments/assets/4222f9b2-92b7-437c-b068-99d8a13528da" />


ההבדל: הגרסה היעילה מבצעת GROUP BY על כל הטבלה המחוברת (JOIN), בעוד הגרסה הלא-יעילה מריצה תת-שאילתה לכל שורה בתוצאות.

מדוע היעילה טובה יותר: ה-GROUP BY מבצע פעולת אגרגציה מרוכזת (Hash Aggregate) על הנתונים שהועלו לזיכרון. השיטה הלא-יעילה גורמת ל-Correlated Subquery, שמשמעותה היא שהשרת מריץ את השאילתה הפנימית אלפי פעמים (מספר השורות ב-person כפול מספר השופטים), מה שמאט את המערכת משמעותית.



תיאור: איתור שחקנים שרשמו "דאבל" שלילי-חיובי: הבקיעו שער וגם ספגו כרטיס (צהוב או אדום) באותו משחק בדיוק בטורניר 2018.


```
SELECT 
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    t.CountryName AS NationalTeam,
    ht.CountryName || ' vs ' || gt.CountryName AS MatchUp,
    m.Stage AS MatchStage,
    MIN(me_goal.Minute) AS GoalMinute,
    MAX(me_card.Minute) AS CardMinute
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me_goal ON pl.ID = me_goal.ID 
JOIN MATCH_EVENT me_card ON pl.ID = me_card.ID AND me_goal.MatchID = me_card.MatchID
JOIN MATCH m ON me_goal.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE me_goal.EventType = 'Goal' 
  AND me_card.EventType IN ('Yellow Card', 'Red Card')
  AND EXTRACT(YEAR FROM m.MatchDate) = 2018
GROUP BY p.ID, p.GivenName, p.FamilyName, t.CountryName, ht.CountryName, gt.CountryName, m.Stage
ORDER BY GoalMinute ASC;


SELECT DISTINCT
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    t.CountryName AS NationalTeam,
    ht.CountryName || ' vs ' || gt.CountryName AS MatchUp,
    m.Stage AS MatchStage,
    
    (SELECT MIN(Minute) FROM MATCH_EVENT me2 WHERE me2.ID = p.ID AND me2.MatchID = m.MatchID AND me2.EventType = 'Goal') AS GoalMinute,
    (SELECT MAX(Minute) FROM MATCH_EVENT me3 WHERE me3.ID = p.ID AND me3.MatchID = m.MatchID AND me3.EventType IN ('Yellow Card', 'Red Card')) AS CardMinute
    
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON p.ID = me.ID
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me4 WHERE me4.ID = p.ID AND me4.MatchID = m.MatchID AND me4.EventType = 'Goal') > 0
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me5 WHERE me5.ID = p.ID AND me5.MatchID = m.MatchID AND me5.EventType IN ('Yellow Card', 'Red Card')) > 0
ORDER BY GoalMinute ASC;
```


<img width="1075" height="709" alt="image" src="https://github.com/user-attachments/assets/66d324f7-2bc2-44fb-81ae-677a05bf11d9" />


ההבדל: הגרסה היעילה משתמשת ב-JOIN יחיד ו-GROUP BY עם סינון HAVING. הגרסה הלא-יעילה מריצה 3-4 תתי-שאילתות שונות בתוך ה-SELECT וה-WHERE.

מדוע היעילה טובה יותר: בגרסה היעילה, הנתונים נסרקים ומוצלבים פעם אחת בתוך טבלאות הזיכרון. בגרסה הלא-יעילה, לכל שחקן ולכל משחק שהוחזר, המערכת נאלצת לבצע "חיפוש מחדש" בטבלת האירועים (לכל אירוע בנפרד: פעם לגולים ופעם לכרטיסים). זה מייצר תנועה בלתי פוסקת של ה-SQL Engine בתוך הנתונים, מה שמכפיל את זמן הביצוע פי כמה וכמה.



תיאור: שליפת רשימת שחקנים שנולדו בשנת 1990 והבקיעו שער במהלך הטורניר, כולל תאריך הלידה המלא שלהם והנבחרת אותה ייצגו.


```
SELECT 
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    EXTRACT(DAY FROM pl.DateOfBirth) || '/' || EXTRACT(MONTH FROM pl.DateOfBirth) || '/' || EXTRACT(YEAR FROM pl.DateOfBirth) AS BirthDate,
    t.CountryName AS NationalTeam,
    m.Stage,
    me.Minute AS GoalMinute,
    m.Tournament
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.ID
JOIN MATCH m ON me.MatchID = m.MatchID
WHERE me.EventType = 'Goal'
  AND EXTRACT(YEAR FROM pl.DateOfBirth) = 1990
ORDER BY pl.DateOfBirth ASC;
```


<img width="998" height="687" alt="image" src="https://github.com/user-attachments/assets/3a94cd49-66c6-4049-8c54-96782e7b7182" />



תיאור: זיהוי משחקים בשלבים מתקדמים (שמינית גמר ומעלה) שבהם קבוצת החוץ הצליחה לנצח את קבוצת הבית, כולל הצגת התוצאה הסופית.


```
WITH match_scores AS (
    SELECT 
        m.matchid,
        SUM(CASE WHEN pl.teamcode = m.hometeamcode THEN 1 ELSE 0 END) AS home_goals,
        SUM(CASE WHEN pl.teamcode = m.guestteamcode THEN 1 ELSE 0 END) AS guest_goals
    FROM match m
    JOIN match_event me ON m.matchid = me.matchid
    JOIN player pl ON me.id = pl.id
    WHERE LOWER(me.eventtype) = 'goal'
    GROUP BY m.matchid
)
SELECT 
    m.matchdate,
    m.stage,
    ht.countryname AS home_team,
    gt.countryname AS guest_team,
    ms.home_goals || ' - ' || ms.guest_goals AS final_score
FROM match m
JOIN match_scores ms ON m.matchid = ms.matchid
JOIN team ht ON m.hometeamcode = ht.teamcode
JOIN team gt ON m.guestteamcode = gt.teamcode
WHERE ms.guest_goals > ms.home_goals
  AND LOWER(m.stage) IN ('semi-final', 'quarter-final', 'round of 16', 'final', 'semi-finals', 'quarter-finals')
ORDER BY m.matchdate DESC;
```


<img width="1054" height="752" alt="image" src="https://github.com/user-attachments/assets/dcb2c6a1-a78b-45c0-bc3f-40384804e275" />



תיאור: רשימת אצטדיונים שבהם נשרק לפחות פנדל אחד במהלך המונדיאל, עם פירוט תכולת האצטדיון וכמות הפנדלים שנשרקו בו.


```
SELECT 
    p_player.givenname || ' ' || p_player.familyname AS player_name,
    t.countryname AS player_team,
    me.eventtype AS card_type,
    EXTRACT(DAY FROM m.matchdate) || '/' || EXTRACT(MONTH FROM m.matchdate) || '/' || EXTRACT(YEAR FROM m.matchdate) AS match_date,
    p_ref.givenname || ' ' || p_ref.familyname AS referee_name
FROM match_event me
JOIN player pl ON me.id = pl.id
JOIN person p_player ON pl.id = p_player.id
JOIN team t ON pl.teamcode = t.teamcode
JOIN match m ON me.matchid = m.matchid
JOIN referee r ON m.refereeid = r.id
JOIN person p_ref ON r.id = p_ref.id
WHERE LOWER(me.eventtype) LIKE '%card%'
ORDER BY m.matchdate DESC;
```


<img width="933" height="756" alt="image" src="https://github.com/user-attachments/assets/7aa54dc2-9a4a-4a84-a160-8086cea98698" />



תיאור: הצגת נבחרות שהבקיעו יותר מ-2 שערים בטורניר, כולל סטטיסטיקה על דקת הבקעת השער הראשון והאחרון של אותה נבחרת.


```
SELECT 
    t.teamcode AS team_code,
    t.countryname AS country_name,
    COUNT(me.matcheventid) AS total_goals_scored,
    MIN(me.minute) AS fastest_goal_minute,
    MAX(me.minute) AS latest_goal_minute
FROM team t
JOIN player pl ON t.teamcode = pl.teamcode
JOIN match_event me ON pl.id = me.id
WHERE LOWER(me.eventtype) = 'goal'
GROUP BY t.teamcode, t.countryname
HAVING COUNT(me.matcheventid) > 2
ORDER BY total_goals_scored DESC;
```


<img width="942" height="728" alt="image" src="https://github.com/user-attachments/assets/4ed712bc-c977-40d8-882e-faded97e1927" />



הסבר: שאילתה זו מזהה שופטים שרשומים בטבלת ה-referee אך שמם לא מופיע אפילו פעם אחת בטבלת ה-match תחת העמודה refereeid.

```
DELETE FROM referee r
WHERE NOT EXISTS (SELECT 1 FROM match m WHERE m.refereeid = r.id);
```

<img width="995" height="741" alt="image" src="https://github.com/user-attachments/assets/bdedfd66-4d6f-41c2-b162-1ddcc0a66686" />







<img width="976" height="558" alt="image" src="https://github.com/user-attachments/assets/a5730f08-56de-4f83-bcc2-a0b0ab45b358" />





<img width="976" height="608" alt="image" src="https://github.com/user-attachments/assets/91fde051-c71d-4ae0-abd9-8d81d9f3378c" />






הסבר: שאילתה זו בודקת את כל האצטדיונים בטבלת ה-stadium אל מול האצטדיונים שמופיעים בטבלת ה-match. כל אצטדיון שלא נמצא בטבלת המשחקים מסומן למחיקה.



```
DELETE FROM stadium
WHERE StadiumID NOT IN (SELECT DISTINCT StadiumID FROM match);
```



<img width="1058" height="749" alt="image" src="https://github.com/user-attachments/assets/0fe73235-ba4c-43f3-b185-1069a8786a3c" />






<img width="819" height="622" alt="image" src="https://github.com/user-attachments/assets/ad6c61cb-f780-4db4-80f6-f2b4d3a52d35" />







<img width="839" height="647" alt="image" src="https://github.com/user-attachments/assets/cf14708b-9c77-4f46-9737-f4c1429b6b45" />





הסבר: זוהי שאילתה "מצומצמת" יותר. היא לא מוחקת את כל האצטדיונים שלא אירחו משחקים, אלא רק את אלו שהם גם קטנים מאוד (פחות מ-10,000 מקומות) וגם לא אירחו משחקים.


```
DELETE FROM stadium
WHERE capacity < 10000 
  AND stadiumid NOT IN (SELECT DISTINCT stadiumid FROM match);
```



<img width="1063" height="706" alt="image" src="https://github.com/user-attachments/assets/c7ce3c75-189d-4771-97ed-a48f5a7ce40e" />






<img width="985" height="653" alt="image" src="https://github.com/user-attachments/assets/64fd6314-2cfb-42a6-9d39-a5cec094cedd" />





<img width="926" height="582" alt="image" src="https://github.com/user-attachments/assets/f61771a6-1b1b-44e2-b52a-ec0231884ccd" />



תיאור השינוי (ALTER TABLE):

```
ALTER TABLE stadium ADD CONSTRAINT chk_stadium_capacity CHECK (capacity >= 0);
```

הסבר: פקודה זו מוסיפה אילוץ ברמת הטבלה שמבטיח שכל ערך בעמודת ה-capacity יהיה גדול או שווה ל-0, ובכך מונעת הזנת נתונים לא הגיוניים (כמו קיבולת שלילית).

<img width="806" height="181" alt="C1" src="https://github.com/user-attachments/assets/c9ff3b5f-41c2-47fb-8802-a46724b48d91" />



תיאור השינוי (ALTER TABLE):

```
ALTER TABLE match_event ADD CONSTRAINT chk_event_minute CHECK (minute BETWEEN 0 AND 120);
```


הסבר: אילוץ זה מוודא שזמן האירוע במשחק נמצא בטווח ההגיוני של משחק כדורגל (0 עד 120 דקות, כולל הארכה). ניסיון להזין דקה 140 נחסם על ידי מסד הנתונים כדי למנוע "נתוני זבל".



<img width="851" height="222" alt="C2" src="https://github.com/user-attachments/assets/29ed8a51-4675-486d-aa63-07ace0f57009" />



תיאור השינוי (ALTER TABLE):


```
ALTER TABLE match ADD CONSTRAINT chk_match_stage CHECK (stage IN ('final', 'semi-final', 'quarter-final', 'round of 16', 'group stage'));
```


הסבר: אילוץ זה משתמש ב-CHECK עם IN כדי להגביל את ערכי עמודת ה-stage לקבוצה סגורה של שלבים חוקיים בטורניר. כל ניסיון להזין שלב שאינו מוגדר מראש (כמו 'Super-Final' בדוגמה) יחסם וישמור על עקביות הנתונים.

<img width="1078" height="263" alt="C3" src="https://github.com/user-attachments/assets/b9793c2b-0d99-46fb-b422-1be3b6941d28" />

COMMIT

<img width="1206" height="639" alt="Commit1" src="https://github.com/user-attachments/assets/46ec63c8-eb39-45d6-92a9-55954e31f862" />

<img width="1227" height="672" alt="Commit2" src="https://github.com/user-attachments/assets/984936d5-6b46-49e3-ae8d-b7c372e40d82" />

<img width="1153" height="581" alt="Commit3" src="https://github.com/user-attachments/assets/efa1e325-39b9-4ba5-b375-6ef0ee9596b6" />

<img width="1192" height="575" alt="Commit4" src="https://github.com/user-attachments/assets/10c1bd5f-bc44-476b-af06-af7c403f68cc" />

<img width="1186" height="587" alt="Commit5" src="https://github.com/user-attachments/assets/3cd47144-b1e5-49ed-9da9-46407fe755d7" />


ROLLBACK

<img width="1043" height="600" alt="Rollback1" src="https://github.com/user-attachments/assets/95d4b6be-0fce-4801-85f2-c58cb641217d" />


<img width="1055" height="561" alt="Rollback2" src="https://github.com/user-attachments/assets/7c5671f0-37e0-4344-8b2b-37c5a447249c" />


<img width="1176" height="592" alt="Rollback3" src="https://github.com/user-attachments/assets/eba3f525-728c-4cf2-9c7c-d148ec66a71a" />


<img width="1080" height="611" alt="Rollback4" src="https://github.com/user-attachments/assets/e26ea8ef-d35f-407b-afe9-40318079ab46" />




INDEXES

<img width="1014" height="769" alt="index-off" src="https://github.com/user-attachments/assets/44a00887-bb3a-40de-8928-05044c395fbf" />



<img width="1002" height="753" alt="index-on" src="https://github.com/user-attachments/assets/e0c99ada-1090-474d-9597-ca12a5187b80" />


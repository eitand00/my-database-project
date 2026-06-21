# דו"ח פרויקט - שלב ד': תכנות בסיס נתונים (PL/pgSQL)

## מבוא
בשלב זה הוספנו לוגיקה עסקית למערכת ההימורים שלנו באמצעות כתיבת פונקציות, פרוצדורות, טריגרים ותוכניות ראשיות ב-PL/pgSQL. הקפדנו לשלב אלמנטים מתקדמים בתכנות בסיסי נתונים על מנת לקבל ציון מירבי:
* שימוש בסמנים (Implicit & Explicit Cursors).
* פונקציה המחזירה סמן (Ref Cursor).
* שימוש בפעולות שינוי נתונים (DML) - הכנסה ועדכון.
* שימוש נרחב בהסתעפויות (IF/ELSE) ולולאות (LOOP, FOR).
* תפיסת שגיאות וטיפול בהן (Exceptions).
* שימוש ברשומות מטיפוס דינמי (%ROWTYPE).

---

## 1. פונקציות (Functions)

### פונקציה 1: Calculate_Potential_Payout
* תיאור מילולי: הפונקציה מקבלת מזהה הימור (p_bet_id) ושולפת את נתוני ההימור ונתוני יחסי הזכייה של המשחק (תוך שימוש ב-Implicit Cursor עם מצב STRICT ורשומות דינמיות מתאימות לטבלאות). באמצעות הסתעפויות, הפונקציה בודקת מהי התוצאה החזויה ומחשבת את סכום הזכייה הפוטנציאלי במקרה של ניצחון. במידה וההימור לא נמצא או חסר נתון, נזרקת חריגה המטופלת בבלוק ה-EXCEPTION.
* הקוד:

CREATE OR REPLACE FUNCTION Calculate_Potential_Payout(p_bet_id INT)
RETURNS NUMERIC AS $$
DECLARE
    -- שימוש ברשומות מטיפוס דינאמי
    v_bet_record bets%ROWTYPE;
    v_odds_record odds%ROWTYPE;
    v_expected_payout NUMERIC := 0;
BEGIN
    -- Implicit Cursor (שליפה ישירה לתוך רשומה עם STRICT שיזרוק חריגה אם אין נתון)
    SELECT * INTO STRICT v_bet_record FROM bets WHERE bet_id = p_bet_id;
    SELECT * INTO STRICT v_odds_record FROM odds WHERE global_match_id = v_bet_record.global_match_id;

    -- הסתעפויות (Branching) לבדיקת יחס הזכייה הרלוונטי - מתוקן ל-odd
    IF v_bet_record.predicted_result = 'Home' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.home_win_odd;
    ELSIF v_bet_record.predicted_result = 'Away' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.away_win_odd;
    ELSIF v_bet_record.predicted_result = 'Draw' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.draw_odd;
    ELSE
        RAISE EXCEPTION 'Invalid predicted result format.';
    END IF;

    RETURN v_expected_payout;

-- טיפול בחריגות (Exceptions)
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Exception Caught: Bet ID % was not found.', p_bet_id;
        RETURN -1;
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
        RETURN -1;
END;
$$ LANGUAGE plpgsql;

* הוכחת תקינות:
* <img width="1437" height="787" alt="image" src="https://github.com/user-attachments/assets/ca27e52a-72f4-4f14-850e-908cdeee7e75" />



### פונקציה 2: Get_Match_Bettors_RefCursor
* תיאור מילולי: הפונקציה מקבלת מזהה משחק (p_global_match_id) ומחזירה מצביע דינמי (Ref Cursor) המכיל את כל ההימורים שבוצעו על משחק זה. הפונקציה מבצעת JOIN בין טבלת ההימורים לטבלת המשתמשים כדי לאסוף את שם המהמר, סכום ההימור, הניחוש והסטטוס.
* הקוד:

CREATE OR REPLACE FUNCTION Get_Match_Bettors_RefCursor(p_global_match_id INT)
RETURNS refcursor AS $$
DECLARE
    -- הגדרת משתנה מסוג רף-קורסור
    v_ref_cur refcursor;
BEGIN
    -- פתיחת הסמן ומילוי שלו בתוצאות השאילתה
    OPEN v_ref_cur FOR  
        SELECT u.full_name, b.bet_amount, b.predicted_result, b.bet_status
        FROM bets b
        JOIN users u ON b.user_id = u.user_id
        WHERE b.global_match_id = p_global_match_id;
        
    -- החזרת המצביע
    RETURN v_ref_cur;
END;
$$ LANGUAGE plpgsql;

* הוכחת תקינות:
<img width="1467" height="803" alt="image" src="https://github.com/user-attachments/assets/10348083-d9a5-4c3a-9903-82be973c47a0" />

---

## 2. פרוצדורות (Procedures)

### פרוצדורה 1: Mass_Update_Stage_Odds
* תיאור מילולי: פרוצדורה המבצעת עדכון המוני ליחסי הזכייה עבור כל המשחקים בשלב מסוים במונדיאל. היא מקבלת את שם השלב ואת מקדם ההכפלה ליחסים. הפרוצדורה עושה שימוש ב-Explicit Cursor ששולף את כל המשחקים הרלוונטיים מהצומת הגלובלי, רצה עליהם בלולאת LOOP, ומעדכנת את טבלת ה-odds באמצעות פקודת UPDATE. במידה ומתרחשת שגיאה, מופעל חריג עם ROLLBACK.
* הקוד:

CREATE OR REPLACE PROCEDURE Mass_Update_Stage_Odds(p_stage VARCHAR, p_boost_factor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_id INT;
    v_counter INT := 0;
    
    -- הגדרת סמן מפורש (Explicit Cursor)
    v_match_cursor CURSOR FOR 
        SELECT gm.GlobalMatchID 
        FROM GLOBAL_MATCH gm
        JOIN MATCH m ON gm.WCMatchID = m.MatchID
        WHERE m.Stage = p_stage AND gm.MatchSource = 'WorldCup';
BEGIN
    -- פתיחת הסמן המפורש
    OPEN v_match_cursor;
    
    LOOP
        -- שליפת הנתונים אחד אחד לתוך המשתנה
        FETCH v_match_cursor INTO v_match_id;
        
        -- תנאי יציאה: כשאין יותר שורות בסמן
        EXIT WHEN NOT FOUND;

        -- DML: עדכון היחסים למשחק הספציפי
        UPDATE odds
        SET 
            home_win_odd = home_win_odd * p_boost_factor,
            away_win_odd = away_win_odd * p_boost_factor,
            draw_odd = draw_odd * p_boost_factor
        WHERE global_match_id = v_match_id;
        
        v_counter := v_counter + 1;
    END LOOP;
    
    -- סגירת הסמן בסיום השימוש
    CLOSE v_match_cursor;
    
    RAISE NOTICE 'Successfully boosted odds for % matches in stage %', v_counter, p_stage;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error encountered during mass update: %', SQLERRM;
        ROLLBACK;
END;
$$;

* הוכחת תקינות:
<img width="1253" height="757" alt="image" src="https://github.com/user-attachments/assets/ae1459a2-9a9b-4000-a671-b6f97868b0e2" />

<img width="1483" height="756" alt="image" src="https://github.com/user-attachments/assets/346b9a89-cd6d-4a50-8517-95837b5eadf9" />

<img width="1070" height="761" alt="image" src="https://github.com/user-attachments/assets/a93f462e-d8d3-4029-9cb9-5396faf70156" />




### פרוצדורה 2: create_bet
* תיאור מילולי: פרוצדורה ליצירת הימור חדש. היא מקבלת מזהה משתמש, משחק, סכום וניחוש. מוודאת תחילה שהניחוש חוקי ושהמשחק קיים. לאחר מכן היא מבצעת 2 פקודות DML: מורידה מהיתרה של המשתמש את סכום ההימור (עדכון ה-Balance) ורושמת את ההימור החדש בטבלת bets (ביצוע INSERT). כוללת טיפול שגיאות ב-Exception ששומר על אמינות הנתונים ומבטל את כל העסקה במקרה של תקלה.
* הקוד:

CREATE OR REPLACE PROCEDURE create_bet(
    p_user_id INT,
    p_global_match_id INT,
    p_amount NUMERIC,
    p_prediction VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_exists BOOLEAN;
    v_new_bet_id INT;
BEGIN
    -- 1. ולידציה של תוצאת ההימור
    IF p_prediction NOT IN ('Home', 'Draw', 'Away') THEN
        RAISE EXCEPTION 'Betting Failed: Invalid prediction syntax. Must be ''Home'', ''Draw'', or ''Away''. Received: "%"', p_prediction;
    END IF;

    -- 2. בדיקה האם המשחק קיים
    SELECT EXISTS(SELECT 1 FROM GLOBAL_MATCH WHERE GlobalMatchID = p_global_match_id) INTO v_match_exists;
    
    IF NOT v_match_exists THEN
        RAISE EXCEPTION 'Betting Failed: Match ID % does not exist.', p_global_match_id;
    END IF;

    -- 3. חישוב מזהה ההימור הבא הפנוי
    SELECT COALESCE(MAX(bet_id), 0) + 1 INTO v_new_bet_id FROM bets;

    -- 4. DML 1: קיזוז הכסף מיתרת המשתמש (עדכון)
    UPDATE users SET balance = balance - p_amount WHERE user_id = p_user_id;

    -- 5. DML 2: רישום ההימור (הכנסה) כולל תאריך ההימור האוטומטי
    INSERT INTO bets (
        bet_id, 
        user_id, 
        global_match_id, 
        bet_amount, 
        predicted_result, 
        bet_status, 
        bet_date
    )
    VALUES (
        v_new_bet_id, 
        p_user_id, 
        p_global_match_id, 
        p_amount, 
        p_prediction, 
        'Pending', 
        CURRENT_DATE 
    );

    RAISE NOTICE 'System: Bet ID % placed successfully for user % on match % on %.', v_new_bet_id, p_user_id, p_global_match_id, CURRENT_DATE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction Aborted: %', SQLERRM;
        ROLLBACK;
END;
$$;

* הוכחת תקינות:
<img width="1292" height="711" alt="image" src="https://github.com/user-attachments/assets/5b44b43b-8653-4560-95a3-f8bc5da9a4c0" />

---

## 3. טריגרים (Triggers)

### טריגר 1: מניעת יתרה שלילית (בזמן UPDATE)
* תיאור מילולי: טריגר מסוג BEFORE UPDATE המופעל על טבלת המשתמשים. הטריגר בודק האם היתרה החדשה לאחר הפעולה (NEW.balance) קטנה מאפס. במידה וכן, הוא חוסם את העדכון וזורק שגיאה שעוצרת את התהליך (חובה כדי למנוע מינוס בחשבונות הלקוחות בעקבות הימורים).
* הקוד:

-- א. פונקציית הטריגר
CREATE OR REPLACE FUNCTION trg_func_prevent_negative_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- אם היתרה המעודכנת קטנה מאפס, אנחנו עוצרים את הפעולה
    IF NEW.balance < 0 THEN
        RAISE EXCEPTION 'Transaction Denied: User % does not have enough funds. Balance cannot drop below 0 (Attempted balance: %)', NEW.user_id, NEW.balance;
    END IF;
    
    -- אם הכל תקין, מאשרים את ביצוע השורה החדשה
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql;

-- ב. חיבור הטריגר לטבלה
CREATE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE OF balance ON users
FOR EACH ROW
EXECUTE FUNCTION trg_func_prevent_negative_balance();

* הוכחת תקינות:
<img width="1190" height="707" alt="image" src="https://github.com/user-attachments/assets/463a5b8e-da18-425f-aea5-10644a7526e0" />


### טריגר 2: תשלום אוטומטי בזכייה בהימור (בזמן UPDATE)
* תיאור מילולי: טריגר מסוג AFTER UPDATE המופעל על טבלת ההימורים. הוא מאזין לשינוי של עמודת הסטטוס. אם הסטטוס משתנה באופן פרטני ל-'Won' (ניצחון), הטריגר שולף את יחס הזכייה המתאים מהמשחק, מכפיל אותו בסכום ההימור, ומבצע באופן עצמאי פקודת UPDATE לעדכון והוספת כספי הזכייה לחשבון המשתמש בטבלת users.
* הקוד:

-- א. פונקציית הטריגר
CREATE OR REPLACE FUNCTION trg_func_payout_on_win()
RETURNS TRIGGER AS $$
DECLARE
    v_odd NUMERIC;
    v_payout NUMERIC;
BEGIN
    -- בדיקה האם סטטוס ההימור עודכן הרגע ל-'Won' 
    IF NEW.bet_status = 'Won' AND (OLD.bet_status IS DISTINCT FROM 'Won') THEN
        
        -- שליפת יחס הזכייה הרלוונטי מהמשחק
        IF NEW.predicted_result = 'Home' THEN
            SELECT home_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Away' THEN
            SELECT away_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Draw' THEN
            SELECT draw_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        END IF;

        -- חישוב והוספת הזכייה לחשבון
        v_payout := NEW.bet_amount * v_odd;
        UPDATE users SET balance = balance + v_payout WHERE user_id = NEW.user_id;
        
        RAISE NOTICE 'Trigger Executed: User % won bet %. Added % to balance.', NEW.user_id, NEW.bet_id, v_payout;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ב. חיבור הטריגר לטבלה
CREATE TRIGGER trg_payout_on_win
AFTER UPDATE OF bet_status ON bets
FOR EACH ROW
EXECUTE FUNCTION trg_func_payout_on_win();

* הוכחת תקינות:
<img width="1451" height="716" alt="image" src="https://github.com/user-attachments/assets/ea31e255-b946-444d-9602-cd4265d2c9ed" />

---

## 4. תוכניות ראשיות (Main Programs)

### תוכנית ראשית 1: ביצוע הימורים וחישוב רווח
* תיאור מילולי: תוכנית (בלוק אנונימי) המבצעת סימולציה של מהמרים. התוכנית רצה בלולאה 3 פעמים, בוחרת במקריות משתמש מהמערכת ומשחק פעיל עם יחסים. מגרילה סכום ותוצאה, ואז מזמנת את פרוצדורת create_bet כדי לרשום את ההימור. מיד לאחר מכן התוכנית מאתרת את ההימור שזה עתה נוצר, ומזמנת את הפונקציה Calculate_Potential_Payout על מנת להציג במסך את הרווח האפשרי במקרה של זכייה.
* הקוד:

DO $$
DECLARE
    v_existing_user_id INT;
    v_match_with_odds INT;
    v_bet_amount NUMERIC;
    v_predictions TEXT[] := ARRAY['Home', 'Draw', 'Away'];
    v_random_prediction VARCHAR;
    v_latest_bet_id INT;
    v_potential_payout NUMERIC;
BEGIN
    RAISE NOTICE '--- Starting Main Program 1: Bet Placement & Payout Calculation ---';

    FOR i IN 1..3 LOOP
        SELECT user_id INTO v_existing_user_id FROM users ORDER BY random() LIMIT 1;
        SELECT global_match_id INTO v_match_with_odds FROM odds ORDER BY random() LIMIT 1;

        v_bet_amount := floor(random() * 150 + 50);
        v_random_prediction := v_predictions[1 + floor(random() * array_length(v_predictions, 1))];

        -- 1. זימון פרוצדורה
        CALL create_bet(v_existing_user_id, v_match_with_odds, v_bet_amount, v_random_prediction);
        SELECT MAX(bet_id) INTO v_latest_bet_id FROM bets WHERE user_id = v_existing_user_id;
        
        -- 2. זימון פונקציה
        v_potential_payout := Calculate_Potential_Payout(v_latest_bet_id);
        
        RAISE NOTICE 'Analytics: Bet ID % has a calculated potential payout of: %', v_latest_bet_id, v_potential_payout;
        RAISE NOTICE '---------------------------------------------------------';
    END LOOP;

    RAISE NOTICE '--- Main Program 1 Completed Successfully ---';
END;
$$;

* הוכחת תקינות:
<img width="1467" height="756" alt="image" src="https://github.com/user-attachments/assets/7cd10b90-52db-4ed0-85a9-006ed2e97d8e" />




### תוכנית ראשית 2: אלגוריתם בוט "חכמת ההמונים"
* תיאור מילולי: תוכנית מתקדמת המדמה אלגוריתם אוטומטי שמהמר על סמך דעת הרוב. התוכנית מאתרת משחק שיש עליו מספר הימורים במערכת, ומזמנת את הפונקציה Get_Match_Bettors_RefCursor כדי לקבל מצביע לכל אותם ההימורים. התוכנית עוברת על הסמן בלולאה תוך שימוש ב-FETCH, מסכמת כמה כסף הושם על כל אחת מהתוצאות האפשריות במשחק זה, ומסיקה מהו הניחוש הפופולארי ביותר ע"י המשתמשים. בסיום, היא מזמנת את הפרוצדורה create_bet כדי לשים הימור אסטרטגי גדול עבור בוט המערכת על אותה תוצאה נבחרת.
* הקוד:

DO $$
DECLARE
    v_bot_name VARCHAR := 'Crowd_Wisdom_Bot';
    v_bot_email VARCHAR := 'bot_' || floor(random() * 10000)::TEXT || '@jct-betting.com';
    v_bot_balance NUMERIC := 100000.0;
    v_bot_id INT;
    
    v_match_id INT;
    v_bettor_cursor refcursor;
    v_bettor_name VARCHAR;
    v_amount NUMERIC;
    v_guess VARCHAR;
    v_status VARCHAR;
    
    v_home_money NUMERIC := 0;
    v_away_money NUMERIC := 0;
    v_draw_money NUMERIC := 0;
    v_chosen_prediction VARCHAR;
    v_bot_bet_amount NUMERIC := 1500.0;
BEGIN
    RAISE NOTICE '--- Starting Main Program 2: Algorithm "Wisdom of the Crowds" ---';

    -- יצירת משתמש עבור הבוט
    CALL create_user(v_bot_name, v_bot_email, v_bot_balance);
    SELECT user_id INTO v_bot_id FROM users WHERE email = v_bot_email;

    -- חיפוש משחק רלוונטי
    SELECT global_match_id INTO v_match_id 
    FROM bets 
    WHERE global_match_id IS NOT NULL 
    GROUP BY global_match_id 
    HAVING COUNT(*) > 1 
    LIMIT 1;

    IF v_match_id IS NOT NULL THEN
        RAISE NOTICE 'Market Analysis: Scanning sentiment for Match ID %...', v_match_id;
        
        -- 1. זימון פונקציה: קבלת הסמן עם הנתונים
        v_bettor_cursor := Get_Match_Bettors_RefCursor(v_match_id);
        
        LOOP
            FETCH v_bettor_cursor INTO v_bettor_name, v_amount, v_guess, v_status;
            EXIT WHEN NOT FOUND;
            
            IF v_guess = 'Home' THEN v_home_money := v_home_money + v_amount;
            ELSIF v_guess = 'Away' THEN v_away_money := v_away_money + v_amount;
            ELSIF v_guess = 'Draw' THEN v_draw_money := v_draw_money + v_amount;
            END IF;
        END LOOP;
        CLOSE v_bettor_cursor;

        RAISE NOTICE 'Money Distribution -> Home: %, Draw: %, Away: %', v_home_money, v_draw_money, v_away_money;

        IF v_home_money >= v_away_money AND v_home_money >= v_draw_money THEN v_chosen_prediction := 'Home';
        ELSIF v_away_money >= v_home_money AND v_away_money >= v_draw_money THEN v_chosen_prediction := 'Away';
        ELSE v_chosen_prediction := 'Draw';
        END IF;

        RAISE NOTICE 'Algorithm Conclusion: Most money is on "%". Executing strategic bot bet...', v_chosen_prediction;

        -- 2. זימון פרוצדורה: ביצוע ההימור בפועל 
        CALL create_bet(v_bot_id, v_match_id, v_bot_bet_amount, v_chosen_prediction);

    ELSE
        RAISE NOTICE 'Analysis Aborted: Not enough betting volume found.';
    END IF;

    RAISE NOTICE '--- Main Program 2 Completed Successfully ---';
END;
$$;

* הוכחת תקינות:
<img width="1467" height="702" alt="image" src="https://github.com/user-attachments/assets/e3948620-e418-48c6-878f-5ea79487f7bc" />

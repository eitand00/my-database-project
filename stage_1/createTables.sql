-- 1. טבלת אנשים (בסיס לשחקנים ושופטים)
CREATE TABLE PERSON (
    ID VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(150)
);

-- 2. טבלת קבוצות/נבחרות
CREATE TABLE TEAM (
    TeamCode VARCHAR(50) PRIMARY KEY,
    CountryName VARCHAR(100),
    Confederation VARCHAR(100)
);

-- 3. טבלת אצטדיונים
CREATE TABLE STADIUM (
    StadiumID VARCHAR(50) PRIMARY KEY,
    City VARCHAR(100),
    Name VARCHAR(150),
    Capacity INT
);

-- 4. טבלת שחקנים (יורשת מ-PERSON)
CREATE TABLE PLAYER (
    ID VARCHAR(50) PRIMARY KEY,
    DateOfBirth DATE, 
    Position VARCHAR(50),
    TeamCode VARCHAR(50),
    FOREIGN KEY (ID) REFERENCES PERSON(ID),
    FOREIGN KEY (TeamCode) REFERENCES TEAM(TeamCode)
);

-- 5. טבלת שופטים (יורשת מ-PERSON)
CREATE TABLE REFEREE (
    ID VARCHAR(50) PRIMARY KEY,
    Years_of_experience INT,
    FOREIGN KEY (ID) REFERENCES PERSON(ID)
);

-- 6. טבלת משחקים (שונתה ל-MATCHES)
CREATE TABLE MATCHES (
    MatchID VARCHAR(50) PRIMARY KEY,
    MatchDate DATE,
    Stage VARCHAR(100),
    HomeTeamCode VARCHAR(50),
    AwayTeamCode VARCHAR(50),
    StadiumID VARCHAR(50),
    RefereeID VARCHAR(50),
    FOREIGN KEY (HomeTeamCode) REFERENCES TEAM(TeamCode),
    FOREIGN KEY (AwayTeamCode) REFERENCES TEAM(TeamCode),
    FOREIGN KEY (StadiumID) REFERENCES STADIUM(StadiumID),
    FOREIGN KEY (RefereeID) REFERENCES REFEREE(ID)
);

-- 7. טבלת אירועי משחק (מעודכנת להצביע ל-MATCHES)
CREATE TABLE MATCH_EVENT (
    Minute VARCHAR(10), 
    MatchID VARCHAR(50),
    EventType VARCHAR(50),
    PlayerID VARCHAR(50),
    PRIMARY KEY (Minute, MatchID, EventType, PlayerID), 
    FOREIGN KEY (MatchID) REFERENCES MATCHES(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES PLAYER(ID)
);

-- 8. טבלת סטטיסטיקות שחקן במשחק (מעודכנת להצביע ל-MATCHES)
CREATE TABLE PLAYER_MATCH_STATS (
    MatchID VARCHAR(50),
    PlayerID VARCHAR(50),
    MinutesPlayed INT,
    DistanceCovered FLOAT,
    PRIMARY KEY (MatchID, PlayerID),
    FOREIGN KEY (MatchID) REFERENCES MATCHES(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES PLAYER(ID)
);
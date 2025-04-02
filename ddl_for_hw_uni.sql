------------------------------------------------------------------------
-- 1. Почистим структуру, если нужно
------------------------------------------------------------------------
DROP TABLE IF EXISTS CoachToGame               CASCADE;
DROP TABLE IF EXISTS PlayerToGame              CASCADE;
DROP TABLE IF EXISTS CoachingStaffAssignments  CASCADE;
DROP TABLE IF EXISTS CompetitionToSponsor      CASCADE;
DROP TABLE IF EXISTS CompetitionSponsorship    CASCADE;
DROP TABLE IF EXISTS Contracts                 CASCADE;
DROP TABLE IF EXISTS Games                     CASCADE;
DROP TABLE IF EXISTS Competitions              CASCADE;
DROP TABLE IF EXISTS Sponsors                  CASCADE;
DROP TABLE IF EXISTS Players                   CASCADE;
DROP TABLE IF EXISTS Nationality               CASCADE;
DROP TABLE IF EXISTS Positions                 CASCADE;
DROP TABLE IF EXISTS Management                CASCADE;
DROP TABLE IF EXISTS Coaches                   CASCADE;

------------------------------------------------------------------------
-- 2. Создаём справочные таблицы: Nationality, Positions
------------------------------------------------------------------------

CREATE TABLE Nationality (
    nationality_id   SERIAL       NOT NULL,
    country_name     TEXT         NOT NULL, 
    -- (или 'nat_info' вместо 'country_name', если хотите оставить старое поле)
    CONSTRAINT pk_nationality PRIMARY KEY (nationality_id)
);

-- Справочник позиций (амплуа)
CREATE TABLE Positions (
    position_id   SERIAL      NOT NULL,
    pos_info      TEXT        NOT NULL,
    CONSTRAINT pk_positions PRIMARY KEY (position_id)
);

------------------------------------------------------------------------
-- 3. Таблица игроков Players (без циклических ссылок)
------------------------------------------------------------------------

CREATE TABLE Players (
    player_id         SERIAL       NOT NULL,
    nationality_id    INT          NOT NULL,
    position_id       INT          NOT NULL,
    player_ps_data    TEXT         NOT NULL,
    player_date_birth DATE         NOT NULL
        CHECK (player_date_birth <= CURRENT_DATE),
    player_number     INT          NOT NULL
        CHECK (player_number > 0),
    height            INT          NOT NULL
        CHECK (height > 0),
    weight            INT          NOT NULL
        CHECK (weight > 0),
    player_phone      TEXT         NOT NULL,
    player_first_name TEXT         NOT NULL,
    player_last_name  TEXT         NOT NULL,
    player_middle_name TEXT,
    CONSTRAINT pk_players PRIMARY KEY (player_id),

    -- Внешний ключ на Nationality
    CONSTRAINT fk_players_nationality
        FOREIGN KEY (nationality_id)
        REFERENCES Nationality (nationality_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    -- Внешний ключ на Positions
    CONSTRAINT fk_players_positions
        FOREIGN KEY (position_id)
        REFERENCES Positions (position_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

-- Индексы на FK (необязательно, но можно)
CREATE INDEX ix_players_nationality_id ON Players(nationality_id);
CREATE INDEX ix_players_position_id    ON Players(position_id);

------------------------------------------------------------------------
-- 4. Таблица Management (бывшая Managment)
------------------------------------------------------------------------

CREATE TABLE Management (
    manager_id          SERIAL      NOT NULL,
    manager_ps_data     TEXT        NOT NULL,
    manager_date_birth  DATE        NOT NULL
        CHECK (manager_date_birth <= CURRENT_DATE),
    manager_phone       TEXT        NOT NULL,
    manager_pos         TEXT        NOT NULL,
    manager_first_name  TEXT        NOT NULL,
    manager_last_name   TEXT        NOT NULL,
    manager_middle_name TEXT,
    CONSTRAINT pk_management PRIMARY KEY (manager_id)
);

------------------------------------------------------------------------
-- 5. Таблица Coaches
------------------------------------------------------------------------

CREATE TABLE Coaches (
    coach_id          SERIAL      NOT NULL,
    coach_ps_data     TEXT        NOT NULL,
    coach_date_birth  DATE        NOT NULL
        CHECK (coach_date_birth <= CURRENT_DATE),
    coach_phone       TEXT        NOT NULL,
    license_info      TEXT        NOT NULL,
    coach_first_name  TEXT        NOT NULL,
    coach_last_name   TEXT        NOT NULL,
    coach_middle_name TEXT,
    CONSTRAINT pk_coaches PRIMARY KEY (coach_id)
);

------------------------------------------------------------------------
-- 6. Таблица CoachingStaffAssignments (бывшая CoachingStaffAssigments)
--    Исправляем поля: assignment_id, assignment_date, assignment_start_date, assignment_end_date
------------------------------------------------------------------------

CREATE TABLE CoachingStaffAssignments (
    assignment_id      SERIAL NOT NULL,
    coach_id           INT    NULL,
    manager_id         INT    NULL,
    assignment_date    DATE   NOT NULL
        CHECK (assignment_date <= CURRENT_DATE),
    role_assigned      TEXT   NOT NULL,

    -- заменяем ch_start_date/ch_end_date на более очевидные названия
    assignment_start_date DATE NOT NULL,
    assignment_end_date   DATE NOT NULL
        CHECK (assignment_end_date >= assignment_start_date),

    CONSTRAINT pk_coachingstaffassignments PRIMARY KEY (assignment_id),

    CONSTRAINT fk_cstaff_coach
        FOREIGN KEY (coach_id)
        REFERENCES Coaches (coach_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_cstaff_manager
        FOREIGN KEY (manager_id)
        REFERENCES Management (manager_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

------------------------------------------------------------------------
-- 7. Таблица Sponsors
------------------------------------------------------------------------

CREATE TABLE Sponsors (
    sponsor_id   SERIAL  NOT NULL,
    sponsor_name TEXT    NOT NULL,
    contact_info TEXT    NOT NULL,
    CONSTRAINT pk_sponsors PRIMARY KEY (sponsor_id)
);

------------------------------------------------------------------------
-- 8. Таблица Competitions
--    Исправляем поле prize_money_recived -> prize_money_received
------------------------------------------------------------------------

CREATE TABLE Competitions (
    comp_id               SERIAL NOT NULL,
    comp_name             TEXT   NOT NULL,
    season                TEXT   NOT NULL,
    final_league_rank     INT    NOT NULL
        CHECK (final_league_rank >= 0),
    prize_money_received  INT    NOT NULL
        CHECK (prize_money_received >= 0),
    CONSTRAINT pk_competitions PRIMARY KEY (comp_id)
);

------------------------------------------------------------------------
-- 9. Таблица Games (связана с Competitions)
------------------------------------------------------------------------

CREATE TABLE Games (
    game_id       SERIAL  NOT NULL,
    comp_id       INT     NULL,
    game_date     DATE    NOT NULL
        CHECK (game_date <= CURRENT_DATE),
    opponent_name TEXT    NOT NULL,
    goals_scored  INT     NOT NULL
        CHECK (goals_scored  >= 0),
    goals_conceded INT    NOT NULL
        CHECK (goals_conceded >= 0),
    tickets_sold  INT     NOT NULL
        CHECK (tickets_sold >= 0),
    tactics       TEXT    NOT NULL,
    scheme        TEXT    NOT NULL,
    CONSTRAINT pk_games PRIMARY KEY (game_id),

    CONSTRAINT fk_games_competitions
        FOREIGN KEY (comp_id)
        REFERENCES Competitions (comp_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE INDEX ix_games_comp_id ON Games (comp_id);

------------------------------------------------------------------------
-- 10. Связующая таблица PlayerToGame
------------------------------------------------------------------------

CREATE TABLE PlayerToGame (
    player_id INT NOT NULL,
    game_id   INT NOT NULL,
    CONSTRAINT pk_playertogame PRIMARY KEY (player_id, game_id),

    CONSTRAINT fk_ptg_player
        FOREIGN KEY (player_id)
        REFERENCES Players (player_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_ptg_game
        FOREIGN KEY (game_id)
        REFERENCES Games (game_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE INDEX ix_player_to_game_player_id ON PlayerToGame(player_id);
CREATE INDEX ix_player_to_game_game_id   ON PlayerToGame(game_id);

------------------------------------------------------------------------
-- 11. Связующая таблица CoachToGame
------------------------------------------------------------------------

CREATE TABLE CoachToGame (
    coach_id INT NOT NULL,
    game_id  INT NOT NULL,
    CONSTRAINT pk_coachtogame PRIMARY KEY (coach_id, game_id),

    CONSTRAINT fk_ctg_coach
        FOREIGN KEY (coach_id)
        REFERENCES Coaches (coach_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_ctg_game
        FOREIGN KEY (game_id)
        REFERENCES Games (game_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE INDEX ix_coach_to_game_coach_id ON CoachToGame(coach_id);
CREATE INDEX ix_coach_to_game_game_id  ON CoachToGame(game_id);

------------------------------------------------------------------------
-- 12. Таблица CompetitionSponsorship (бывшая CompSp)
--     Убираем дублирующийся CHECK, оставляем annual_payment >= 0 и start_date <= end_date
------------------------------------------------------------------------

CREATE TABLE CompetitionSponsorship (
    comp_sponsor_id     SERIAL  NOT NULL,
    comp_annual_payment DECIMAL NOT NULL
        CHECK (comp_annual_payment >= 0),
    contr_start_date    DATE    NOT NULL,
    contr_end_date      DATE    NOT NULL
        CHECK (contr_end_date >= contr_start_date),
    CONSTRAINT pk_comp_sponsorship PRIMARY KEY (comp_sponsor_id)
);

------------------------------------------------------------------------
-- 13. Таблица CompetitionToSponsor (бывшая CompToSponsor)
------------------------------------------------------------------------

CREATE TABLE CompetitionToSponsor (
    comp_sponsor_id INT NOT NULL,
    comp_id         INT NOT NULL,
    CONSTRAINT pk_comp_to_sponsor PRIMARY KEY (comp_sponsor_id, comp_id),

    CONSTRAINT fk_cts_sponsorship
        FOREIGN KEY (comp_sponsor_id)
        REFERENCES CompetitionSponsorship (comp_sponsor_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_cts_competitions
        FOREIGN KEY (comp_id)
        REFERENCES Competitions (comp_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE INDEX ix_competition_to_sponsor_csid ON CompetitionToSponsor(comp_sponsor_id);
CREATE INDEX ix_competition_to_sponsor_cid  ON CompetitionToSponsor(comp_id);

------------------------------------------------------------------------
-- 14. Таблица Contracts (связь: игрок - спонсор)
--     Исправляем CHECKи, убираем дублирующиеся (end_date >= start_date и т.д.)
------------------------------------------------------------------------

CREATE TABLE Contracts (
    contract_id            SERIAL  NOT NULL,
    player_id              INT     NULL,
    sponsor_id             INT     NULL,
    contract_number        INT     NOT NULL
        CHECK (contract_number > 0),
    signing_date           DATE    NOT NULL,
    start_date             DATE    NOT NULL,
    end_date               DATE    NOT NULL
        CHECK (end_date >= start_date),
    club_salary            DECIMAL NOT NULL
        CHECK (club_salary >= 0),
    sponsor_annual_payment DECIMAL NOT NULL
        CHECK (sponsor_annual_payment >= 0),

    CONSTRAINT pk_contracts PRIMARY KEY (contract_id),

    CONSTRAINT fk_contracts_player
        FOREIGN KEY (player_id)
        REFERENCES Players (player_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_contracts_sponsor
        FOREIGN KEY (sponsor_id)
        REFERENCES Sponsors (sponsor_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    -- Дополнительный CHECK: дата подписания <= дате начала (если это строго нужно)
    CHECK (signing_date <= start_date)
);

CREATE INDEX ix_contracts_player_id  ON Contracts(player_id);
CREATE INDEX ix_contracts_sponsor_id ON Contracts(sponsor_id);

-- 25. Контракты с российскими игроками по годам (где > 2 контрактов)
SELECT
  EXTRACT(YEAR FROM c.signing_date) AS contract_year,
  COUNT(*) AS contract_count
FROM Contracts c
JOIN Players p ON c.player_id = p.player_id
JOIN Nationality n ON p.nationality_id = n.nationality_id
WHERE n.country_name = 'Russia'
GROUP BY contract_year
HAVING COUNT(*) > 2;

-- 26. Спонсоры с контрактами ≥ 3 лет
SELECT DISTINCT s.sponsor_name
FROM Sponsors s
JOIN Contracts c ON s.sponsor_id = c.sponsor_id
WHERE (c.end_date - c.start_date) >= INTERVAL '3 years';

-- 27. Самый старший тренер
SELECT *
FROM Coaches
WHERE coach_date_birth = (SELECT MIN(coach_date_birth) FROM Coaches);

-- 28. Спонсор, оплачивающий только одного русского игрока
SELECT s.sponsor_id, s.sponsor_name
FROM Sponsors s
JOIN Contracts c ON s.sponsor_id = c.sponsor_id
JOIN Players p ON c.player_id = p.player_id
JOIN Nationality n ON p.nationality_id = n.nationality_id
WHERE n.country_name = 'Russia'
GROUP BY s.sponsor_id, s.sponsor_name
HAVING COUNT(DISTINCT p.player_id) = 1;

-- 29. Состав (игра) с наибольшим числом забитых голов
SELECT *
FROM Games
ORDER BY goals_scored DESC
LIMIT 1;

-- 30. Тренеры из составов с >5 тренеров
SELECT c.coach_last_name,
       c.coach_first_name || ' ' ||
       COALESCE(SUBSTRING(c.coach_middle_name FROM 1 FOR 1) || '.', '') AS initials
FROM Coaches c
JOIN CoachToGame ctg ON c.coach_id = ctg.coach_id
WHERE ctg.game_id IN (
  SELECT game_id
  FROM CoachToGame
  GROUP BY game_id
  HAVING COUNT(*) > 5
);

-- 31. Спонсор с наибольшим числом немецких игроков
SELECT s.sponsor_name
FROM Sponsors s
JOIN Contracts c ON s.sponsor_id = c.sponsor_id
JOIN Players p ON c.player_id = p.player_id
JOIN Nationality n ON p.nationality_id = n.nationality_id
WHERE n.country_name = 'Germany'
GROUP BY s.sponsor_id, s.sponsor_name
ORDER BY COUNT(DISTINCT p.player_id) DESC
LIMIT 1;

-- 32. Спонсор с наибольшим числом контрактов с одним игроком
WITH sponsor_player_ct AS (
  SELECT sponsor_id, player_id, COUNT(*) AS num_deals
  FROM Contracts
  GROUP BY sponsor_id, player_id
),
sponsor_max AS (
  SELECT sponsor_id, MAX(num_deals) AS max_deals_for_same_player
  FROM sponsor_player_ct
  GROUP BY sponsor_id
)
SELECT s.sponsor_name
FROM sponsor_max sm
JOIN Sponsors s ON sm.sponsor_id = s.sponsor_id
ORDER BY sm.max_deals_for_same_player DESC
LIMIT 1;

-- 33. Руководители с игроками, у которых контракт истекает в текущем месяце
SELECT DISTINCT
       m.manager_last_name,
       m.manager_first_name || ' ' ||
       COALESCE(SUBSTRING(m.manager_middle_name FROM 1 FOR 1) || '.', '') AS manager_initials
FROM Management m
JOIN CoachingStaffAssignments csa ON m.manager_id = csa.manager_id
JOIN CoachToGame ctg ON ctg.coach_id = csa.coach_id
JOIN PlayerToGame ptg ON ctg.game_id = ptg.game_id
JOIN Contracts c ON ptg.player_id = c.player_id
WHERE EXTRACT(MONTH FROM c.end_date) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM c.end_date) = EXTRACT(YEAR FROM CURRENT_DATE);

-- 34. Последние 3 контракта
SELECT p.player_last_name, p.player_first_name, p.player_middle_name
FROM Players p
JOIN Contracts c ON p.player_id = c.player_id
ORDER BY c.signing_date DESC
LIMIT 3;

-- 35. Спонсоры без контрактов последние полгода
SELECT s.sponsor_name
FROM Sponsors s
LEFT JOIN Contracts c ON s.sponsor_id = c.sponsor_id
GROUP BY s.sponsor_id, s.sponsor_name
HAVING MAX(c.signing_date) < CURRENT_DATE - INTERVAL '6 months'
   OR MAX(c.signing_date) IS NULL;

-- 36. Все игроки + «продлить контракт», если контракт истекает в этом году
SELECT p.*,
       CASE
         WHEN EXISTS (
           SELECT 1 FROM Contracts c
           WHERE c.player_id = p.player_id
             AND EXTRACT(YEAR FROM c.end_date) = EXTRACT(YEAR FROM CURRENT_DATE)
         )
         THEN 'продлить контракт'
         ELSE ''
       END AS note
FROM Players p;

-- 37. Прибыль по контракту на 12.04.2019
SELECT p.player_id, p.player_last_name, p.player_first_name, p.player_middle_name,
       COALESCE(SUM(c.club_salary + c.sponsor_annual_payment), 0) AS total_profit
FROM Players p
LEFT JOIN Contracts c ON p.player_id = c.player_id
  AND '2019-04-12' BETWEEN c.start_date AND c.end_date
GROUP BY p.player_id, p.player_last_name, p.player_first_name, p.player_middle_name;

-- 38. Тёзки среди тренеров и игроков
SELECT c.coach_id, c.coach_last_name, c.coach_first_name, c.coach_middle_name,
       p.player_id, p.player_last_name, p.player_first_name, p.player_middle_name
FROM Coaches c
JOIN Players p ON c.coach_last_name = p.player_last_name
              AND c.coach_first_name = p.player_first_name
              AND (
                (c.coach_middle_name IS NULL AND p.player_middle_name IS NULL) OR
                c.coach_middle_name = p.player_middle_name
              );

-- 39. Все однофамильцы по базе
WITH all_persons AS (
  SELECT coach_last_name, coach_first_name, coach_middle_name FROM Coaches
  UNION ALL
  SELECT player_last_name, player_first_name, player_middle_name FROM Players
  UNION ALL
  SELECT manager_last_name, manager_first_name, manager_middle_name FROM Management
)
SELECT coach_last_name AS last_name, coach_first_name, coach_middle_name,
       COUNT(*) AS cnt
FROM all_persons
GROUP BY last_name, coach_first_name, coach_middle_name
HAVING COUNT(*) > 1;

-- 40. Общее количество однофамильцев
WITH all_persons AS (
  SELECT coach_last_name, coach_first_name, coach_middle_name FROM Coaches
  UNION ALL
  SELECT player_last_name, player_first_name, player_middle_name FROM Players
  UNION ALL
  SELECT manager_last_name, manager_first_name, manager_middle_name FROM Management
),
grouped AS (
  SELECT coach_last_name, coach_first_name, coach_middle_name, COUNT(*) AS cnt
  FROM all_persons
  GROUP BY coach_last_name, coach_first_name, coach_middle_name
)
SELECT SUM(cnt) FROM grouped WHERE cnt > 1;

-- 41. Тренеры, тренировавшие ≥2 состава без пропущенных шайб
SELECT c.coach_id, c.coach_last_name, c.coach_first_name, c.coach_middle_name
FROM Coaches c
JOIN CoachToGame ctg ON c.coach_id = ctg.coach_id
JOIN Games g ON ctg.game_id = g.game_id
WHERE g.goals_conceded = 0
GROUP BY c.coach_id, c.coach_last_name, c.coach_first_name, c.coach_middle_name
HAVING COUNT(DISTINCT g.game_id) >= 2;

-- 42. Спонсоры и инициалы руководителей в одном столбце
SELECT sponsor_name AS entity FROM Sponsors
UNION
SELECT manager_last_name || ' ' || 
       SUBSTRING(manager_first_name FROM 1 FOR 1) || '.' || 
       COALESCE(SUBSTRING(manager_middle_name FROM 1 FOR 1) || '.', '') 
FROM Management
ORDER BY entity;

-- 43. Есть ли игроки с просроченным контрактом
SELECT CASE 
  WHEN EXISTS (
    SELECT 1 FROM Players p
    WHERE NOT EXISTS (
      SELECT 1 FROM Contracts c
      WHERE c.player_id = p.player_id
        AND c.end_date >= CURRENT_DATE
    )
  )
  THEN 'Есть игроки с просроченным контрактом'
  ELSE 'Нет просроченных контрактов'
END AS message;

-- 44. Для каждого спонсора — все руководители + количество игроков (если есть)
SELECT s.sponsor_name,
       m.manager_last_name, m.manager_first_name, m.manager_middle_name,
       COUNT(DISTINCT c.player_id) AS player_count
FROM Sponsors s
CROSS JOIN Management m
LEFT JOIN Contracts c ON c.sponsor_id = s.sponsor_id
GROUP BY s.sponsor_name, m.manager_last_name, m.manager_first_name, m.manager_middle_name;

-- 45. Игроки, заключившие контракты со всеми спонсорами
SELECT p.player_last_name, p.player_first_name, p.player_middle_name
FROM Players p
JOIN Contracts c ON p.player_id = c.player_id
GROUP BY p.player_id, p.player_last_name, p.player_first_name, p.player_middle_name
HAVING COUNT(DISTINCT c.sponsor_id) = (SELECT COUNT(*) FROM Sponsors);

-- 46. Спонсор без контрактов >3 лет и с макс. ежегодным платежом
WITH inactive AS (
  SELECT s.sponsor_id, s.sponsor_name
  FROM Sponsors s
  JOIN Contracts c ON c.sponsor_id = s.sponsor_id
  GROUP BY s.sponsor_id, s.sponsor_name
  HAVING MAX(c.signing_date) < CURRENT_DATE - INTERVAL '3 years'
)
SELECT i.sponsor_name
FROM inactive i
JOIN Contracts c ON i.sponsor_id = c.sponsor_id
GROUP BY i.sponsor_name
ORDER BY MAX(c.sponsor_annual_payment) DESC
LIMIT 1;

-- 47. Игроки из самого успешного состава (по разнице голов)
WITH best_game AS (
  SELECT game_id
  FROM Games
  ORDER BY (goals_scored - goals_conceded) DESC
  LIMIT 1
)
SELECT p.player_last_name, p.player_first_name, p.player_middle_name
FROM PlayerToGame ptg
JOIN best_game bg ON ptg.game_id = bg.game_id
JOIN Players p ON p.player_id = ptg.player_id;

-- 48. Национальность, состав которой однонациональный
WITH one_nat_games AS (
  SELECT ptg.game_id
  FROM PlayerToGame ptg
  JOIN Players p ON ptg.player_id = p.player_id
  GROUP BY ptg.game_id
  HAVING COUNT(DISTINCT p.nationality_id) = 1
)
SELECT DISTINCT n.country_name
FROM PlayerToGame ptg
JOIN one_nat_games ong ON ptg.game_id = ong.game_id
JOIN Players p ON ptg.player_id = p.player_id
JOIN Nationality n ON p.nationality_id = n.nationality_id;

-- 49. Тренеры, тренирующие межнациональные команды сейчас
WITH multi_nat_games AS (
  SELECT ptg.game_id
  FROM PlayerToGame ptg
  JOIN Players p ON ptg.player_id = p.player_id
  GROUP BY ptg.game_id
  HAVING COUNT(DISTINCT p.nationality_id) > 1
)
SELECT DISTINCT c.coach_last_name, c.coach_first_name, c.coach_middle_name,
       c.coach_date_birth, c.coach_phone
FROM CoachToGame ctg
JOIN Coaches c ON ctg.coach_id = c.coach_id
JOIN Games g ON ctg.game_id = g.game_id
WHERE g.game_id IN (SELECT game_id FROM multi_nat_games)
  AND g.game_date >= CURRENT_DATE;

-- 50. Самый дорогой игрок у тренера Иванова И.И.И.
WITH target_coach AS (
  SELECT coach_id FROM Coaches
  WHERE coach_last_name = 'Ivanov' AND coach_first_name = 'Ivan' AND coach_middle_name = 'Ivanovich'
),
ivan_games AS (
  SELECT game_id FROM CoachToGame WHERE coach_id IN (SELECT coach_id FROM target_coach)
),
players_in_games AS (
  SELECT DISTINCT player_id FROM PlayerToGame WHERE game_id IN (SELECT game_id FROM ivan_games)
),
player_costs AS (
  SELECT player_id, MAX(club_salary + sponsor_annual_payment) AS total_cost
  FROM Contracts
  GROUP BY player_id
)
SELECT p.player_last_name, p.player_first_name, p.player_middle_name
FROM players_in_games pig
JOIN player_costs pc ON pig.player_id = pc.player_id
JOIN Players p ON p.player_id = pig.player_id
ORDER BY pc.total_cost DESC
LIMIT 1;

-- 51. Игроки с перерывами в карьере > 1 года
WITH cte AS (
  SELECT player_id, start_date,
         LAG(end_date) OVER (PARTITION BY player_id ORDER BY start_date) AS prev_end
  FROM Contracts
)
SELECT DISTINCT p.player_last_name, p.player_first_name, p.player_middle_name
FROM cte
JOIN Players p ON cte.player_id = p.player_id
WHERE prev_end IS NOT NULL AND (start_date - prev_end) > INTERVAL '1 year';

-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;
DROP VIEW IF EXISTS CAcollege;
DROP VIEW IF EXISTS slg;
DROP VIEW IF EXISTS lslg;
DROP VIEW IF EXISTS salary_statistics;
DROP VIEW IF EXISTS maxid;
DROP VIEW IF EXISTS bins_statistics;
DROP VIEW IF EXISTS bins;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era) FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear from people 
  where weight>300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear from people where nameFirst like '% %'
  order by nameFirst, nameLast ASC --ASC at the end is optional (the default option)
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthYear, avg(height), count(*) from people group by birthYear order by birthYear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthYear, avg(height) as av, count(*) from people group by birthYear 
  having av>70 order by birthYear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT nameFirst, nameLast, people.playerID as id1, yearid from people inner join halloffame 
  on id1=halloffame.playerid where inducted='Y'order by yearid desc, id1
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT nameFirst, nameLast, people.playerID as id1, schoolid, yearid from people inner join halloffame,
  (select * from collegeplaying inner join schools on collegeplaying.schoolid=schools.schoolid where schoolstate='CA') as a
  on id1=halloffame.playerid and halloffame.playerID=a.playerID where inducted='Y'order by yearid desc, schoolid, id1
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  select a.playerid, nameFirst, nameLast, schoolid from people inner join 
  (select halloffame.playerid, schoolid from halloffame left outer join collegeplaying 
  on halloffame.playerid=collegeplaying.playerid where inducted='Y') as a 
  on people.playerid=a.playerid order by a.playerid desc, schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  select a.playerid, namefirst, namelast, yearid, slg from people inner join 
  (select playerID, (h+h2b+2.0*h3b+3*hr)/ab as slg, yearid from batting where ab>50 order by slg desc limit 10) as a 
  on people.playerid=a.playerid order by slg desc, yearid, a.playerid
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  --sum(h), sum(h2b) as s2, sum(h3b) as s3, sum(hr) as s4,
  select a.playerid, namefirst, namelast, lslg from people inner join
  (SELECT playerid, sum(ab) as abtot, sum(h+h2b+2*h3b+3.0*hr)/sum(ab) as lslg
  from batting group by playerid having abtot>50 order by lslg desc limit 10) as a
  on people.playerid=a.playerid order by lslg desc, a.playerID 
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  select namefirst, namelast, lslg from people inner join
  (SELECT playerid, sum(ab) as abtot, sum(h+h2b+2*h3b+3.0*hr)/sum(ab) as lslg
  from batting group by playerid having abtot>50 and lslg>(SELECT sum(h+h2b+2*h3b+3.0*hr)/sum(ab) as mlslg
  from batting group by playerid having playerID='mayswi01')) as a
  on people.playerid=a.playerid
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, min(salary), max(salary), avg(salary) from salaries group by yearid order by yearid
;


-- Helper table for 4ii
DROP TABLE IF EXISTS binids;
CREATE TABLE binids(binid);
INSERT INTO binids VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binids.binid, binids.binid*(m2-m1)/10+m1 as low, (binids.binid+1)*(m2-m1)/10+m1 as high, count from
  (select case cast(10.0*(salary-m1)/(m2-m1) as int) when 10 then 9 else cast(10.0*(salary-m1)/(m2-m1) as int) end as binid,
  m1, m2, count(*) as count from (SELECT min(salary) as m1, max(salary) as m2 from salaries where yearid='2016')
  left outer join (select * from salaries where yearid='2016') group by binid) as a 
  inner join binids on a.binid=binids.binid
  -- last bin needs special treatment
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  select y2, m2-m1 as mindiff, n2-n1 as maxdiff, a2-a1 as avgdiff from 
  (SELECT yearid, min(salary) as m1, max(salary) as n1, avg(salary) as a1 from salaries group by yearid) inner join 
  (SELECT yearid as y2, min(salary) as m2, max(salary) as n2, avg(salary) as a2 from salaries group by yearid having yearid>1985)
  on yearid=y2-1 order by y2;
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT people.playerID, namefirst, nameLast, salary, yearid from people inner join 
  (select playerid, salary, yearid from salaries where (yearid='2000' and salary=(select max(salary) from salaries where yearid='2000'))
  or (yearid='2001' and salary=(select max(salary) from salaries where yearid='2001'))) as a
  on a.playerID=people.playerID
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT teamid, max(salary)-min(salary) as diffAvg from
  (SELECT playerid, salary from salaries where yearid='2016') as s inner join
  (select playerid, teamid from allstarfull where yearID='2016') as a
  on s.playerID=a.playerID group by teamid
;

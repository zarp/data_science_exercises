------------------ QUESTION 1 ----------------------
create schema exercise;

create table exercise.contracts (symbol text primary key, minimum integer);
create table exercise.orders (order_id text primary key, symbol text, quantity integer, foreign key (symbol) references exercise.contracts(symbol));
insert into exercise.contracts (symbol, minimum) values ('TRXU21', 100), ('ETHU21', 1), ('LTCU21', 1);
\copy exercise.orders from '/tmp/sql_exercise_data/orders.csv' csv header

/* 
Please provide the following data for contracts ETHU21, LTCU21, and TRXU21:

Q1_1: # of orders using the Minimum Order Quantity / total # of orders using any Order Quantity since listed, by contract
Q1_2: # of orders using Smaller than 10x of the Minimum Order Quantity / total # of orders using any Order Quantity since listed, by contract
Q1_3: Total Order Quantity of orders using the Minimum Order Quantity / Total Order Quantity of orders using any Order Quantity since listed, by contract
Q1_4: Total Order Quantity of orders using Smaller than 10x of the Minimum Order Quantity (Lot Size) / Total Order Quantity of orders using any Order Quantity since listed, by contract
	
Data:
Contract = orders.symbol
TOQ = orders.quantity -- This field is in number of contracts, not number of lots.
MOQ = contracts.minimum -- This field is in number of contracts.
*/

-- Answers for Q1:
WITH joined as
(SELECT cons.symbol, o.quantity, cons.minimum, o.quantity = cons.minimum as qty_eq_min, o.quantity < 10*cons.minimum as qty_less_10xmin
FROM exercise.contracts cons 
JOIN exercise.orders o ON o.symbol = cons.symbol)
SELECT symbol, 
	COUNT(CASE WHEN qty_eq_min THEN 1 END)::decimal / COUNT(*) as Q1_1_answer,
	COUNT(CASE WHEN qty_less_10xmin THEN 1 END)::decimal / COUNT(*) as Q1_2_answer,
	SUM(quantity*qty_eq_min::int)::decimal / SUM(quantity) as Q1_3_answer,
	SUM(quantity*qty_less_10xmin::int)::decimal / SUM(quantity) as Q1_4_answer
FROM joined GROUP BY symbol;

/* 
Output for Q1:
 symbol |      q1_1_answer       |      q1_2_answer       |        q1_3_answer         |        q1_4_answer         
--------+------------------------+------------------------+----------------------------+----------------------------
 LTCU21 | 0.08170515097690941385 | 0.30017761989342806394 |     0.00075913854278405809 |     0.01146959320075913854
 TRXU21 | 0.00000000000000000000 | 0.00719424460431654676 | 0.000000000000000000000000 | 0.000027789136035760648201
 ETHU21 | 0.34563758389261744966 | 0.53691275167785234899 |     0.02554563492063492063 |     0.08506944444444444444
(3 rows)
*/

------------------ QUESTION 2 ----------------------
create extension if not exists "uuid-ossp";
create table exercise.asset
	(
		id uuid primary key default uuid_generate_v4()
		, name text not null unique
	);

insert into exercise.asset (name) values ('BTC'), ('ETH'); 

create table exercise.price
	(
		asset_id uuid
		, price_usd numeric not null
		, day date not null
	);
	
insert into exercise.price (asset_id, price_usd, day)
	select a.id, x.price_usd, x.day from 
	(values ('BTC'::text, 49966.06::numeric, '2021-06-05'::date)
		, ('BTC'::text, 36740::numeric, '2021-06-04'::date)
		, ('BTC'::text, 27301.05::numeric, '2021-06-07'::date)
		, ('BTC'::text, 41082.06::numeric, '2021-06-03'::date)
		, ('BTC'::text, 49966.04::numeric, '2021-06-05'::date)
		, ('BTC'::text, 2659.52::numeric, '2021-06-05'::date)
		, ('ETH'::text, 2768.45::numeric, '2021-06-03'::date)
		, ('ETH'::text, 2659.52::numeric, '2021-06-05'::date)
		, ('ETH'::text, 2734.15::numeric, '2021-06-06'::date)
	) x (name, price_usd, day)
	JOIN exercise.asset a on a.name = x.name;
	
-- Q: What is the price of BTC in USD on the 5th of June 2021?

-- A: This is an ambiguous question. There are 3 entries for BTC on this date (and 1 for ETH):
SELECT a.name, p.price_usd, p.day FROM exercise.price p
JOIN exercise.asset a ON p.asset_id = a.id WHERE p.day = '2021-06-05';
/*
 name | price_usd |    day     
------+-----------+------------
 BTC  |   2659.52 | 2021-06-05
 BTC  |  49966.04 | 2021-06-05
 BTC  |  49966.06 | 2021-06-05
 ETH  |   2659.52 | 2021-06-05
(4 rows)

I see two potential issues here:
	1. The price in the 1st row (2659.52) doesn't look right - it is identical to the ETH price on the same date (see last/4th row). The other 2 results are more believable.
	2. Considering that we can have > 1 entry for a given asset on a given day, we need to clarify what exactly does "the price of BTC" mean (daily average?, opening or closing price?)

So, I would:
	1. Mention the data quality issue out to whoever asked me this question and/or owns the database, and try to figure out how this erroneous entry made it into the database.
	2. Ask the requestor what type/definition of "price" were they interested in.

*/


------------------ QUESTION 3,4,5 ----------------------
create table exercise.medium
	(medium text primary key);

-- These are obtained from referrers - telling us where an online visitor is coming from - and represent one marketing channel ("medium") we paid money for (Facebook), and two that are "free": Google (i.e. SEO), and direct visits with no referrers.
insert into exercise.medium (medium) values ('Facebook'), ('Google'), ('Direct');

create table exercise.user_log
	(
	user_id integer
	, time timestamptz
	, medium text
	, primary key (user_id, time)
	, foreign key (medium) references exercise.medium (medium)
);

insert into exercise.user_log
	(user_id, time, medium)
	values
	(1, '2021-03-10 10:10:10+07', 'Google')
	, (2, '2021-03-14 10:10:26-06', 'Facebook')
	, (3, '2021-03-14 05:21:04+01', 'Facebook')
	, (1, '2021-03-13 06:34:47+07', 'Google')
	, (2, '2021-03-14 15:10:26-06', 'Google')
	, (1, '2021-03-15 19:20:42+07', 'Google')
	, (1, '2021-03-15 20:30:37+07', 'Direct')
	, (1, '2021-03-16 22:05:23+02', 'Facebook')
	, (1, '2021-03-18 08:10:26+02', 'Google')
	, (2, '2021-03-11 11:56:19+03', 'Direct')
	, (1, '2021-03-14 15:21:04+07', 'Facebook')
	, (2, '2021-03-12 13:43:58-06', 'Facebook')	
	, (2, '2021-03-13 19:10:37-06', 'Direct')
	, (1, '2021-03-11 19:10:26+07', 'Direct')
	, (2, '2021-03-14 17:15:41-06', 'Direct')
	, (2, '2021-03-14 20:10:26-06', 'Direct')
	, (3, '2021-03-14 06:19:57+01', 'Direct')
	, (2, '2021-03-13 19:10:39-06', 'Google')
	, (1, '2021-03-12 21:13:11+07', 'Facebook')
	, (3, '2021-03-14 08:48:00+01', 'Google')
	, (1, '2021-03-14 09:31:32+07', 'Direct');

/*
/*
The rules:
- any entry within 10 seconds of another is a duplicate; take the first.
- a visit is defined as new if there has not been another entry in the last 30 minutes for that user.

Question 3: assuming $1/visit, what did we pay Google for the visits on the 13th March 2021 UTC?

Question 4: what percentage of visits were direct on the 14th March 2021 SGT?
	
Question 5 (optional): give 40% of attribution to the first medium ever used by the user, and 60% to the last. Assume one order per user. What is the % attributed to each medium?
*/

-- A: If I understand correctly, the 10 second rule applies even if two entries came from two different media (e.g. 18:10:37-07 from Direct, and 18:10:39-07 from Google):
SELECT *, time - lag(time) OVER (ORDER BY time) AS delta
FROM exercise.user_log
ORDER BY time;
/*
 user_id |          time          |  medium  |     delta      
---------+------------------------+----------+----------------
       1 | 2021-03-09 20:10:10-07 | Google   | 
       2 | 2021-03-11 01:56:19-07 | Direct   | 1 day 05:46:09
       1 | 2021-03-11 05:10:26-07 | Direct   | 03:14:07
       1 | 2021-03-12 07:13:11-07 | Facebook | 1 day 02:02:45
       2 | 2021-03-12 12:43:58-07 | Facebook | 05:30:47
       1 | 2021-03-12 16:34:47-07 | Google   | 03:50:49
       2 | 2021-03-13 18:10:37-07 | Direct   | 1 day 01:35:50
       2 | 2021-03-13 18:10:39-07 | Google   | 00:00:02
       1 | 2021-03-13 19:31:32-07 | Direct   | 01:20:53
       3 | 2021-03-13 21:21:04-07 | Facebook | 01:49:32
       3 | 2021-03-13 22:19:57-07 | Direct   | 00:58:53
       3 | 2021-03-14 00:48:00-07 | Google   | 02:28:03
       1 | 2021-03-14 01:21:04-07 | Facebook | 00:33:04
       2 | 2021-03-14 09:10:26-07 | Facebook | 07:49:22
       2 | 2021-03-14 14:10:26-07 | Google   | 05:00:00
       2 | 2021-03-14 16:15:41-07 | Direct   | 02:05:15
       2 | 2021-03-14 19:10:26-07 | Direct   | 02:54:45
       1 | 2021-03-15 05:20:42-07 | Google   | 10:10:16
       1 | 2021-03-15 06:30:37-07 | Direct   | 01:09:55
       1 | 2021-03-16 13:05:23-07 | Facebook | 1 day 06:34:46
       1 | 2021-03-17 23:10:26-07 | Google   | 1 day 10:05:03
(21 rows)
*/

-- For the purpose of this exercise I'll stick to this definition, so we'll filter out 1 entry in the table above

CREATE TEMPORARY TABLE log_filtered AS
SELECT *
FROM  (
   SELECT *, time - lag(time, 1, 'epoch') OVER (ORDER BY time) AS delta
   FROM exercise.user_log
   ) t
WHERE  delta > interval '10 sec'
ORDER BY time;

/* 
As for the 2nd rule (30 minute rule to define visits): the smallest remaining delta is ~ 33 minutes, 
so we don't need to do any additional filtering and can treat each remaining row in the log_filtered table as a separate visit:
*/
SELECT MIN(delta) FROM log_filtered;
/*
   min    
----------
 00:33:04
(1 row)
*/

-- Now, to answer the questions:
-- Question 3: assuming $1/visit, what did we pay Google for the visits on the 13th March 2021 UTC?
-- Answer 3:
SELECT COUNT(*) FROM log_filtered
WHERE medium = 'Google' AND DATE(time AT TIME ZONE 'UTC') = '2021-03-13';
/*
 count 
-------
     0
(1 row)

The answer is zero considering there are no Mar, 13th entries (UTC time) at all
The reason we just used COUNT(*) to get dollar amount is due to the fact that 1 row = 1 visit (see above), and 1 visit = $1, so 1 row = $1
*/


-- Q4: what percentage of visits were direct on the 14th March 2021 SGT?
-- A4: 50%

WITH mar14_subset AS
(SELECT * FROM log_filtered
WHERE DATE(time AT TIME ZONE 'SGT') = '2021-03-14'),
mar14_direct_subset AS 
(SELECT * FROM mar14_subset
WHERE medium = 'Direct')
SELECT (
        100*(SELECT COUNT(*) FROM mar14_direct_subset)::decimal /
        (SELECT COUNT(*) FROM mar14_subset)
        ) as percent_direct;
/*
   percent_direct    
---------------------
 50.0000000000000000
(1 row)
*/

-- Question 5 (optional): give 40% of attribution to the first medium ever used by the user, and 60% to the last. Assume one order per user. What is the % attributed to each medium?
SELECT medium, SUM(attrib) attribution FROM 
	(
		(SELECT DISTINCT ON (user_id) *, 0.4 attrib
		FROM log_filtered
		ORDER BY user_id,  time ASC)
		UNION
		(SELECT DISTINCT ON (user_id) *, 0.6 attrib
		FROM log_filtered
		ORDER BY user_id,  time DESC)
	) t3
GROUP BY medium;
/* Answer 5:
  medium  | attribution 
----------+-------------
 Facebook |         0.4
 Direct   |         1.0
 Google   |         1.6
(3 rows)
*/

------------------ QUESTIONS 6 ----------------------
begin;
create table exercise.english
	(author text, title text, paragraphs text);

create table exercise.french
	(author text, title text, paragraphs text);

-- Modify the path to your local directory.
\copy exercise.english from '/tmp/sql_exercise_data/english.csv' csv header
\copy exercise.french from '/tmp/sql_exercise_data/french.csv' csv header

create table exercise.book as
	select 'English'::text as language, author, title, paragraphs from exercise.english
	union all
	select 'French'::text as language, author, title, paragraphs from exercise.french;

drop table exercise.english; drop table exercise.french;
commit;

/*
Question 6:
Implement FTS in both French and English indexing the title and paragraphs column stemming with the appropriate dictionaries. 
Use the index to return the set of authors who have said "propriété individuelle" in French or "valuable asset" in English as a single query.
*/

-- Answer 6:
ALTER TABLE exercise.book ADD COLUMN paragraph_vector tsvector;
UPDATE exercise.book SET paragraph_vector = to_tsvector(language::regconfig, title || ' ' || paragraphs);

CREATE INDEX book_idx ON exercise.book USING GIN(paragraph_vector); 

SELECT author FROM exercise.book
WHERE 
	(language = 'English' AND paragraph_vector @@ to_tsquery(language::regconfig, 'valuable <-> asset')) OR
	(language = 'French' AND paragraph_vector @@ to_tsquery(language::regconfig, 'propriété <-> individuelle'));
/*
                    author                     
-----------------------------------------------
 George S. Harney
 Henry Kalloch Rowe
 William Budington Duryee
 United States. National Conservation Congress
 Gilbert Parker
 Mark Twain
 Edith Wharton
 Norman F. Joly
 Oscar Wilde
 Various
 David Graham Phillips
 E. Phillips (Edward Phillips) Oppenheim
 Richard Harding Davis
 R. D. (Robert Dalziel) Cumming
 Albert Bigelow Paine
 George Whale
 Anonymous
 Jules Lemaître
 Jack London
 M. (François) Guizot
(21 rows)
*/
	

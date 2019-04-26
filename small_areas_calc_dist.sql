/**********************************************************/
/*				GET PRIMARY KEY OF TABLE				  */
/**********************************************************/
SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS data_type
FROM   pg_index i
JOIN   pg_attribute a ON a.attrelid = i.indrelid
                     AND a.attnum = ANY(i.indkey)
WHERE  i.indrelid = 'kildare_centroid_geoms'::regclass
AND    i.indisprimary;

/**********************************************************/
/*					GET POSTGIS VERSION	                  */
/**********************************************************/
SELECT PostGIS_full_version();
SELECT version();

-- drop subset table if exists
drop table if exists kildare_small_areas_with_pop_stats1

-- create a subset of data for test purposes
CREATE TABLE kildare_small_areas_with_pop_stats1
  AS (SELECT *
FROM ireland_small_areas_with_pop_stats
WHERE countyname = 'Kildare');

select * from kildare_small_areas_with_pop_stats1
select * from ireland_small_areas_with_pop_stats




select * from kildare_small_areas_centroids

SELECT id_0, edname, t4_1_tc
FROM kildare_small_areas_centroids
ORDER BY the_geom <-> st_setsrid(st_makepoint(-90,40),4326)
--LIMIT 742;

-- delete rows where total children is zero
delete from kildare_small_areas_centroids
where t4_1_tc = 0
-- 2 rows affected
/**********************************************************/
/**********************************************************/
/**********************************************************/

/**********************************************************/
/**********************************************************/

/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/

select * from newbridge_small_areas_centroids_reduced_cols
-- 84 rows returned

-- drop test_santa_costs table if exists
drop table if exists newbridge_santa_costs

-- create new table with subset santa costs 
CREATE TABLE newbridge_santa_costs as
(SELECT start_pt.geom as start_geom,
 start_pt.guid,
 start_pt.id as start_id, 
 start_pt.edname as start_name, -- get id and name of starting pt
 end_pt.geom as end_geom,
 end_pt.id as end_id,
 end_pt.edname as end_name,
 end_pt.t4_2_tct as child_population,  -- get id, name & pop of ending pt
 ST_Distance(start_pt.geom, end_pt.geom) as calc_dist, -- calc distance between points
 (end_pt.t4_2_tct/end_pt.shape__are)/ST_Distance(start_pt.geom, end_pt.geom) as cost_score -- calc cost_score = (pop density/distance)
FROM newbridge_small_areas_centroids_reduced_cols as start_pt, -- all start points
 	 newbridge_small_areas_centroids_reduced_cols as end_pt -- all destinations
     --Kildare_small_areas_with_pop_stats as areas 	 
WHERE not start_pt.geom = end_pt.geom -- where starting and ending points are different
AND ST_Distance(start_pt.geom, end_pt.geom) != 0 -- and distance between starting and ending points are not zero
--AND ST_Within(start_pt.the_geom, areas.geom)
--AND ST_Within(end_pt.the_geom, areas.geom)
ORDER BY start_id asc, cost_score desc) -- order resulting view by score descending

select * from newbridge_santa_costs
-- 6972 rows returned (84^2 - 84 = 6972)



/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
select * from kildare_santa_costs
--546860 rows

-- drop santa_costs table if exists
drop table if exists kildare_santa_costs

-- create new table with all santa costs 
CREATE TABLE kildare_santa_costs as
(SELECT start_pt.id_0 as start_id, 
 start_pt.edname as start_name, -- get id and name of starting pt
 end_pt.id_0 as end_id,
 end_pt.edname as end_name,
 end_pt.t4_1_tc as child_population,  -- get id, name & pop of ending pt
 ST_Distance(start_pt.the_geom, end_pt.the_geom) as calc_dist, -- calc distance between points
 end_pt.t4_1_tc/ST_Distance(start_pt.the_geom, end_pt.the_geom) as calc_score -- calc cost_score = (pop/distance)
FROM kildare_small_areas_centroids as start_pt, -- all start points
 	 kildare_small_areas_centroids as end_pt -- all destinations
WHERE not start_pt.the_geom = end_pt.the_geom -- where starting and ending points are different
AND ST_Distance(start_pt.the_geom, end_pt.the_geom) != 0 -- and distance between starting and ending points are not zero
ORDER BY start_id asc, calc_score desc) -- order resulting view by score descending
-- ORDER BY start_pt.the_geom <-> end_pt.the_geom
-- the ' <-> ' symbol compares distances without reporting them

select * from kildare_santa_costs
--546860 rows
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/



	
																		
/*****/
--Step 5: Work out scores to apply to each route segment
-- start_geom, guid, start_id, start_name
-- (0) define function nn - pick top row in cost_table


/***********************************************************************************************************************/
--		SQL CODE BELOW USED TO CREATE PROJECT TABLES AND QUERIES
/***********************************************************************************************************************/

-- (1) find starting point, initially whatever point is first in list


-- (2) calculate all “nearest neighbour” scores from all centroids to all other centroids
CREATE TABLE short_route_santa_costs as
(SELECT start_pt.centroid as start_geom,
 	start_pt.guid,
 	start_pt.id as start_id, 
	start_pt.edname as start_name, -- get id and name of starting pt
 	end_pt.centroid as end_geom,
 	end_pt.id as end_id,
 	end_pt.edname as end_name,
	end_pt.t4_2_tct as child_population,  -- get id, name & pop of ending pt
 	ST_Distance(start_pt.centroid, end_pt.centroid) as calc_dist, -- calc distance between points
 	(end_pt.t4_2_tct/end_pt.shape__are)/ST_Distance(start_pt.centroid, end_pt.centroid) as cost_score -- calc cost_score = (pop density/distance)
FROM short_route as start_pt, -- all start points
 	 short_route as end_pt -- all destinations	 
WHERE not start_pt.centroid = end_pt.centroid -- where starting and ending points are different
AND ST_Distance(start_pt.centroid, end_pt.centroid) != 0 -- and distance between starting and ending points are not zero
ORDER BY ST_YMax(start_pt.centroid) desc, cost_score desc) -- order resulting view by latitude descending and score descending

-- select * from short_route_santa_costs
-- 30 rows returned (6^2 - 6 = 30)
-- select ST_GeometryType(start_geom) from short_route_santa_costs
-- all ST_Point

select * from newbridge_santa_costs
-- 6972 rows returned (84^2 - 84 = 6972)

-- get copy to use for testing
create table temp_cost_table as 
(select * from short_route_santa_costs)
-- select * from temp_cost_table
-- drop table if exists temp_cost_table

-- create route_table structure
create table short_route_table (
	point_geom geometry,
	point_guid varchar(80),
	point_id bigint,
	point_name varchar(80)
	)
-- select * from short_route_table
-- drop table if exists short_route_table
					   
					   
--CREATE TABLE points (name varchar, point geometry);
--INSERT INTO points VALUES ('Origin', 'POINT(0 0)'),
--  ('North', 'POINT(0 1)'),
--  ('East', 'POINT(1 0)'),
--  ('West', 'POINT(-1 0)'),
--  ('South', 'POINT(0 -1)');
--SELECT name, ST_AsText(point) FROM points;	

-- THE ROUTE TABLE IS POPULATED AT MOMENT - 84 ENTRIES!!!
-- create route_table structure
create table route_table (
	like temp_cost_table -- just to begin with
    including defaults
    including constraints
    including indexes);
-- select * from route_table
-- drop table if exists route_table

-- (3) SQL ‘insert’ current point into a route table
with current_pt as (select * from temp_cost_table limit 1) -- top row because the table was sorted when built
insert into route_table (start_geom, guid, start_id, start_name)
	select start_geom, guid, start_id, start_name 
		from current_pt;
select * from route_table

-- (4) delete all rows from temp_cost_table which use the current point (either start or end)
delete from temp_cost_table
using route_table
where temp_cost_table.start_geom = route_table.start_geom or temp_cost_table.end_geom = route_table.start_geom

-- (5) the new current point is the NN point that maximises the NN score above
select * from temp_cost_table limit 1

-- (6) check original table length > 0 i.e. route incomplete (y/n)
select is_route_complete()

-- (7) repeat from 2 above

/***********************************************************************************************************************/
/***********************************************************************************************************************/

CREATE OR REPLACE FUNCTION is_route_complete()
RETURNS varchar AS $$
DECLARE
	count_route integer;
	route_complete varchar;
BEGIN
SELECT COUNT(*) INTO count_route FROM temp_cost_table;
IF count_route > 0 THEN route_complete = 'route not complete';
ELSE route_complete = 'route complete';
END IF;
RETURN route_complete;
END;
$$
LANGUAGE PLpgSQL

-- this was created for testing instead of manipulating route_table
-- route_table has 84 pts (Newbridge area) or 740pts (Co. Kildare)
create table short_route as
(SELECT * FROM route_table limit 6);
select * from short_route
-- drop table if exists short_route
-- select ST_GeometryType(start_geom) from short_route

-- generate all the kildare small area centroids
create table kildare_centroid_geoms as
(select st_centroid(ke.geom) as centroid, ke.* from county_kildare_small_areas_reduced_cols as ke)
select * from kildare_centroid_geoms
-- drop table if exists kildare_centroid_geoms
-- select ST_GeometryType(centroid) from kildare_centroid_geoms

-- generate all the newbridge small area centroids
create table newbridge_centroid_geoms as
(select st_centroid(nwbr.geom) as centroid, nwbr.* from newbridge_small_areas_reduced_cols as nwbr)
select * from newbridge_centroid_geoms
-- drop table if exists newbridge_centroid_geoms
-- select ST_GeometryType(centroid) from newbridge_centroid_geoms

-- create a short_route of datapoints for test purposes
CREATE TABLE short_route
  AS (SELECT * FROM newbridge_centroid_geoms limit 6); -- retreive subset of rows for test purposes
-- select * from short_route
-- drop table if exists short_route


create table county_kildare_geom
as (select * from counties where name_tag = 'Kildare')
select * from county_kildare_geom

select * from counties
-- drop table if exists counties

create table county_kildare_houses
as (select * from county_kildare_buildings where type = 'house')
select * from county_kildare_houses

select count(*) from ireland_small_areas_with_pop_stats

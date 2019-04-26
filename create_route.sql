-- generate all the kildare small area centroids
create table kildare_centroid_geoms as
(select st_centroid(ke.geom) as centroid, ke.* from county_kildare_small_areas_reduced_cols as ke)
select * from kildare_centroid_geoms
-- select * from kildare_centroid_geoms
-- drop table if exists kildare_centroid_geoms
-- select ST_GeometryType(centroid) from kildare_centroid_geoms

-- generate all the newbridge small area centroids
create table newbridge_centroid_geoms as
(select st_centroid(nwbr.geom) as centroid, nwbr.* from newbridge_small_areas_reduced_cols as nwbr)
select * from newbridge_centroid_geoms
-- select * from newbridge_centroid_geoms
-- drop table if exists newbridge_centroid_geoms
-- select ST_GeometryType(centroid) from newbridge_centroid_geoms

-- create a short_list of datapoints for test purposes
CREATE TABLE short_list
  AS (SELECT * FROM newbridge_centroid_geoms limit 6); -- retreive subset of rows for test purposes
-- select * from short_list
-- drop table if exists short_list

-- create new table with column for short_route 'costs' associated with each route segment
-- calculate all costs based on formula
CREATE TABLE short_list_santa_costs as
(SELECT start_pt.centroid as start_geom,
 	start_pt.id as start_id, 
	start_pt.edname as start_name, -- get id and name of starting pt
 	end_pt.centroid as end_geom,
 	end_pt.id as end_id,
 	end_pt.edname as end_name,
	end_pt.t4_2_tct as child_population,  -- get id, name & pop of ending pt
 	ST_Distance(start_pt.centroid, end_pt.centroid) as calc_dist, -- calc distance between points
 	(end_pt.t4_2_tct/end_pt.shape__are)/ST_Distance(start_pt.centroid, end_pt.centroid) as cost_score -- calc cost_score = (pop density/distance)
FROM short_list as start_pt, -- all start points
 	 short_list as end_pt -- all destinations	 
WHERE not start_pt.centroid = end_pt.centroid -- where starting and ending points are different
AND ST_Distance(start_pt.centroid, end_pt.centroid) != 0 -- and distance between starting and ending points are not zero
-- the order by statement is incorrect!!!
ORDER BY ST_YMax(start_pt.centroid) desc, cost_score desc) -- order resulting view by latitude descending and score descending
-- select * from short_list_santa_costs
-- drop table if exists short_list_santa_costs

-- create table (with pk) to hold list of all points on route
create table short_route(pkid SERIAL PRIMARY KEY, pt_geom geometry,pt_id integer,pt_name varchar(80))				 
-- select * from short_route
-- drop table if exists short_route
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/
-- (3) SQL ‘insert’ current point into a route table
with current_pt as (select * from short_list_santa_costs limit 1) -- top row because the table was sorted when built
insert into short_route (pt_geom, pt_id, pt_name)
	select start_geom, start_id, start_name
		from current_pt;
with current_pt as (select * from short_list_santa_costs limit 1) -- top row because the table was sorted when built
insert into short_route (pt_geom, pt_id, pt_name)
	select end_geom, end_id, end_name
		from current_pt;
																																	   
-- select * from short_route
-- drop table if exists short_route
-- select ST_GeometryType(pt_geom) from short_route

-- (3) SQL ‘insert’ current point into a route table using function
CREATE FUNCTION insert_current2pts() 
  RETURNS VOID AS 
$$ 
with current_pt as (select * from short_list_santa_costs limit 1)
	INSERT INTO short_route(pt_geom, pt_id, pt_name)
		SELECT start_geom, start_id, start_name
			from current_pt;
with current_pt as (select * from short_list_santa_costs limit 1)
	INSERT INTO short_route(pt_geom, pt_id, pt_name)
		SELECT end_geom, end_id, end_name
			from current_pt;
$$ 
LANGUAGE sql STRICT;
/********************************************************************************************************************/
/********************************************************************************************************************/

/********************************************************************************************************************/
/********************************************************************************************************************/
-- (4) delete all rows from temp_cost_table which use the current point (either start or end)
delete from short_list_santa_costs
using short_route
where (short_list_santa_costs.start_id = short_route.pt_id OR short_list_santa_costs.end_id = short_route.pt_id)
-- select * from short_list_santa_costs

-- (4) delete all rows from temp_cost_table which use the current point (either start or end) using FUNCTION
CREATE FUNCTION delete_last2pts() 
  RETURNS VOID AS 
$$ 
delete from short_list_santa_costs
using short_route
where (short_list_santa_costs.start_id = short_route.pt_id OR short_list_santa_costs.end_id = short_route.pt_id)
$$ 
LANGUAGE sql STRICT;
/********************************************************************************************************************/
/********************************************************************************************************************/

																								 
/********************************************************************************************************************/
/********************************************************************************************************************/
-- function to check if route complete
-- uses temp table copied from costs table
CREATE OR REPLACE FUNCTION is_route_complete()
RETURNS bit AS $$
DECLARE
	count_route integer;
	route_complete bit;
BEGIN
SELECT COUNT(*) INTO count_route FROM short_list_santa_costs;
IF count_route > 0 THEN route_complete = 0;
ELSE route_complete = 1;
END IF;
RETURN route_complete;
END;
$$
LANGUAGE PLpgSQL
/********************************************************************************************************************/
/********************************************************************************************************************/

																								 
/********************************************************************************************************************/
/********************************************************************************************************************/

																								 
												 
																								 
CREATE OR REPLACE FUNCTION build_route_table() 
RETURNS VOID AS $$
DECLARE
route_complete integer;
  BEGIN
    LOOP
      	PERFORM  insert_current2pts();
		PERFORM pg_sleep(0.5);
		PERFORM  delete_last2pts();
		route_complete := (select is_route_complete.is_route_complete from is_route_complete());
      	EXIT WHEN route_complete > 0;
    END LOOP;
  END;
$$ LANGUAGE plpgsql;

select build_route_table()

select * from short_route
-- drop table if exists short_route 
select * from short_list_santa_costs
-- drop table if exists short_list_santa_costs

create table route_line as
(select st_makeline(short_route.pt_geom) as route from short_route)
-- select * from route_line
-- drop table if exists route_line
-- select ST_GeometryType(route) from route_line

												
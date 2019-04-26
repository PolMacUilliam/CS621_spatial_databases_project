-- generate all the kildare small area centroids
create table kildare_centroid_geoms as
(select st_centroid(ke.geom) as centroid, ke.* from county_kildare_small_areas_reduced_cols as ke)
select * from kildare_centroid_geoms
-- select * from kildare_centroid_geoms
-- drop table if exists kildare_centroid_geoms
ALTER TABLE kildare_centroid_geoms ADD PRIMARY KEY (id);
-- select ST_GeometryType(centroid) from kildare_centroid_geoms
								 
/********************************************************************************************************************/
/********************************************************************************************************************/

-- generate all the newbridge small area centroids
create table newbridge_centroid_geoms as
(select st_centroid(nwbr.geom) as centroid, nwbr.* from newbridge_small_areas_reduced_cols as nwbr)
select * from newbridge_centroid_geoms
-- select * from newbridge_centroid_geoms
-- drop table if exists newbridge_centroid_geoms
-- select ST_GeometryType(centroid) from newbridge_centroid_geoms
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/

-- create new table with column for kildare_santa_costs 'costs' associated with each route segment
-- calculate all costs based on formula
CREATE TABLE kildare_santa_costs as
(SELECT start_pt.centroid as start_geom,
 	start_pt.id as start_id, 
	start_pt.edname as start_name, -- get id and name of starting pt
 	end_pt.centroid as end_geom,
 	end_pt.id as end_id,
 	end_pt.edname as end_name,
	end_pt.t4_2_tct as child_population,  -- get id, name & pop of ending pt
 	ST_Distance(start_pt.centroid, end_pt.centroid) as calc_dist, -- calc distance between points
 	(end_pt.t4_2_tct/end_pt.shape__are)/ST_Distance(start_pt.centroid, end_pt.centroid) as cost_score -- calc cost_score = (pop density/distance)
FROM kildare_centroid_geoms as start_pt, -- all start points
 	 kildare_centroid_geoms as end_pt -- all destinations	 
WHERE not start_pt.centroid = end_pt.centroid -- where starting and ending points are different
AND ST_Distance(start_pt.centroid, end_pt.centroid) != 0 -- and distance between starting and ending points are not zero
-- the order by statement is incorrect!!!
ORDER BY ST_YMax(start_pt.centroid) desc, cost_score desc) -- order resulting view by latitude descending and score descending
-- select * from kildare_santa_costs
-- drop table if exists kildare_santa_costs
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/

-- create table (with pk) to hold list of all points on Newbridge route
create table kildare_route(pkid SERIAL PRIMARY KEY, pt_geom geometry,pt_id integer,pt_name varchar(80))				 
-- select * from kildare_route
-- drop table if exists kildare_route
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/
																									 
-- (3) SQL ‘insert’ current point into newbridge_route table using function
CREATE or replace FUNCTION insert_current2pts() 
  RETURNS VOID AS 
$$ 
with current_pt as (select * from kildare_santa_costs limit 1)
	INSERT INTO kildare_route(pt_geom, pt_id, pt_name)
		SELECT start_geom, start_id, start_name
			from current_pt;
with current_pt as (select * from kildare_santa_costs limit 1)
	INSERT INTO kildare_route(pt_geom, pt_id, pt_name)
		SELECT end_geom, end_id, end_name
			from current_pt;
$$ 
LANGUAGE sql STRICT;																									 
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/
																									 
-- (4) delete all rows from newbridge_santa_costs which use the current point (either start or end) using FUNCTION
CREATE or replace FUNCTION delete_last2pts() 
  RETURNS VOID AS 
$$ 
delete from kildare_santa_costs
using kildare_route
where (kildare_santa_costs.start_id = kildare_route.pt_id OR kildare_santa_costs.end_id = kildare_route.pt_id)
$$ 
LANGUAGE sql STRICT;
																								 
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
SELECT COUNT(*) INTO count_route FROM kildare_santa_costs;
IF count_route > 0 THEN route_complete = 0;
ELSE route_complete = 1;
END IF;
RETURN route_complete;
END;
$$
LANGUAGE PLpgSQL
																								 
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

/********************************************************************************************************************/
/********************************************************************************************************************/

-- run function to build route table
select build_route_table()
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/

select * from kildare_route
-- drop table if exists kildare_route 
select * from kildare_santa_costs
-- drop table if exists kildare_santa_costs
																								 
/********************************************************************************************************************/
/********************************************************************************************************************/

create table kildare_route_line as
(select st_makeline(kildare_route.pt_geom) as route from kildare_route)
-- select * from kildare_route_line
-- drop table if exists kildare_route_line
-- select ST_GeometryType(route) from kildare_route_line
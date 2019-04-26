select * from experiment_table_with_santa_costs

select *
from experiment_table_with_santa_costs
where cost_score = (select max(cost_score) from experiment_table_with_santa_costs)
limit 1 

drop table if exists kildare_sqm_areas

CREATE TABLE kildare_sqm_areas as
(select *, ST_Area(geom) as sqm_area
 from kildare_small_areas_with_pop_stats)

select * from kildare_sqm_areas

*POWER(0.3048,2
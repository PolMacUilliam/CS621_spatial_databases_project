-- create table, copied from all_ireland_small_areas shapefile with census data
CREATE table cs621_project_kildare_small_areas AS
SELECT *
FROM aa_ireland_small_areas_census
WHERE countyname = 'Kildare';

-- drop unused cols
alter table cs621_project_kildare_small_areas
drop column nuts1, drop column nuts1name,
drop column nuts2, drop column nuts2name,
drop column nuts3, drop column nuts3name,
drop column csoed, drop column osied,
drop column sa_pub2011, drop column area,
drop column changecode, drop column esri_oid,
drop column t1_1agetm, drop column t1_1agetf,
drop column t1_1agett, drop column t6_8_o,
drop column t6_8_ta, drop column t6_8_uhh,
drop column t6_8_ovd, drop column t6_8_t,
drop column t4_2_ncu15, drop column t4_2_1cu15,
drop column t4_2_2cu15, drop column t4_2_3cu15,
drop column t4_2_tcu15, drop column t4_2_nco15,
drop column t4_2_1co15, drop column t4_2_2co15,
drop column t4_2_3co15, drop column t4_2_4co15,
drop column t4_2_ge5co, drop column t4_2_tco15,
drop column t4_2_ncuo1, drop column t4_2_1cuo1,
drop column t4_2_2cuo1, drop column t4_2_3cuo1,
drop column t4_2_4cuo1, drop column t4_2_ge5_1,
drop column t4_2_tcuo1, drop column t4_2_nct,
drop column t4_2_1ct, drop column t4_2_2ct,
drop column t4_2_3ct, drop column t4_2_4ct,
drop column t4_2_ge5ct, drop column t4_2_4cu15,
drop column t4_2_ge5cu

-- ensure kildare data has correct spatial reference, so add to qgis canvas
select st_transform(cs621_project_kildare_small_areas.geom,4326) from cs621_project_kildare_small_areas
-- create spatial index
CREATE INDEX spidx ON cs621_project_kildare_small_areas USING GIST (geom);
-- select * from cs621_project_kildare_small_areas
-- drop table cs621_project_kildare_small_areas




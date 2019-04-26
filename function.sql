CREATE TABLE test_table_subset AS (SELECT * FROM test_table WHERE countyname = 'Kildare');
SELECT * FROM test_table_subset

SELECT * FROM test_table

/**********************************************/
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

/**********************************************/
drop function is_route_complete()

/**********************************************/

select is_route_complete()
# segment-growth-simulation

This is a small procedure to generate a segment growth simulation in Oracle.
The idea is to run the segment_growth_trend procedure for all segments in a specified schema, and store it in a table, so we may query the top segments with hightest estimation growth.

The steps to run the simulation are:

1.- Download all files in the database host server and start sqlplus located in the same filesystem.

	test_dbms_space_growth_trend.sql
	proc_segment_growth_simulation.sql
	create_segment_growth_table.sql

2.- Ensure DBMS_SPACE package can be executed properly, user has all privileges and all DBA stuff by runing this test:
	SQL> @test_dbms_space_growth_trend.sql
	
	NOTE: EXCEPTION in chrow processing -  code: -14551  msg: ORA-14551 for the first row is an acceptable value!
	
3.- Run create_segment_growth_table script. It will create a table named CAPACITY_SEGMENTS to store the simulation results.
	SQL> @create_segment_growth_table.sql
    DROP TABLE CAPACITY_SEGMENTS
           *
	ERROR in line 1:
	ORA-00942: table or view does not exists

	Table created.

	NOTE: The script first tries to drop the table in case it exists, so this output is acceptable.

4.- Run the procedure script.

	SQL> @proc_segment_growth_simulation.sql
	
	Procedure created.
	
5.- Launch a simulation.

	SQL> exec CHECK_SEGMENT_GROWTH('HR')

    PL/SQL procedure successfully completed.
	
	
Enjoy!
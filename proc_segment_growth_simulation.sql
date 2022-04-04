create or replace procedure CHECK_SEGMENT_GROWTH (p_owner varchar2)
as
    cursor c_segments is 
	Select owner, segment_name, tablespace_name,  Substr(segment_type, 1, 30) segment_type, partition_name, bytes size_mb
      From dba_Segments
     Where owner = p_owner
       And Instr(segment_name,'BIN$') = 0 
       And Instr(segment_type,'LOB')  = 0
       And Length(segment_name) < 31
      Order By segment_Name, partition_name; 
	
    cursor c_estimation (v_owner varchar2, v_segment varchar2,v_type varchar2,v_partition varchar2) is
    Select *
      From Table(Dbms_Space.Object_Growth_Trend(v_owner, v_segment, v_type, v_partition))
    Order By 1 /*Timepoint*/, 4 /*Quality*/;
	
	v_position_estimation number;
	v_initial_space_used number;
	v_space_current number;
	v_space_future number;
	v_pct_ocupation number;
	
begin
    DBMS_OUTPUT.ENABLE;
    for x in c_segments
	loop
	    DBMS_OUTPUT.PUT_LINE('v_owner:= '||x.owner||' v_segment:= '||x.segment_name||' v_type:= '||x.segment_type);
		-- Follow up output
		
		v_position_estimation :=0;
	    v_initial_space_used  :=0;
	    v_space_current       :=0;
	    v_space_future        :=0;
	    v_pct_ocupation       :=0;
		
		for y in c_estimation(x.owner, x.segment_name, x.segment_type,x.partition_name)
		loop
				if v_position_estimation=0 then
						v_initial_space_used:=y.space_usage;
						v_space_current:=y.space_usage;
						v_space_future:=y.space_usage;
						v_pct_ocupation:=round(y.space_usage/y.space_alloc,2)*100;
						v_position_estimation:=1;
				end if;
				if trunc(y.timepoint)=trunc(systimestamp) then
						v_space_current:=y.space_usage;
						v_pct_ocupation:=round(y.space_usage/y.space_alloc,2)*100;
						v_position_estimation:=2;
				end if;
				if v_position_estimation=2 then
						v_space_future:=y.space_usage;
				end if;
		end loop;
		insert into CAPACITY_SEGMENTS
		values (  x.owner,
				  x.segment_name,
				  x.segment_type,
				  x.partition_name,
				  x.tablespace_name,
				  x.size,
				  v_initial_space_used,
				  v_space_current,
				  v_space_future,
				  v_pct_ocupation,
				  sysdate);
		
	end loop;
end;
/
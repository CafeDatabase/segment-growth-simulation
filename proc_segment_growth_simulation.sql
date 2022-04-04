create or replace procedure CHECK_SEGMENT_GROWTH (p_owner varchar2)
as
    cursor c_segments is select owner, segment_name, substr(segment_type,1,30) segment_type, bytes/1024/1024 size_mb from dba_segments where owner=p_owner;
    cursor c_estimation (v_owner varchar2, v_segment varchar2,v_type varchar2)
        is select * from table(dbms_space.OBJECT_GROWTH_TREND(v_owner,v_segment,v_type)) order by timepoint,quality;
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
		v_position_estimation :=0;
	    v_initial_space_used  :=0;
	    v_space_current  :=0;
	    v_space_future  :=0;
	    v_pct_ocupation  :=0;
		if x.segment_type like '%PARTITION%' then
				v_position_estimation:=0;
				for y in c_estimation(x.owner, x.segment_name, x.segment_type)
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
				if x.segment_type like '%INDEX%' then
						insert into CAPACITY_SEGMENTS
							values (  x.owner,
									(select index_name from dba_ind_partitions where partition_name=x.segment_name and index_owner=x.owner),
									x.segment_type,
									x.segment_name,
									x.size_mb,
									v_initial_space_used,
									v_space_current,
									v_space_future,
									v_pct_ocupation,
									sysdate);
				else 
						insert into CAPACITY_SEGMENTS
							values (  x.owner,
									(select table_name from dba_tab_partitions where partition_name=x.segment_name and table_owner=x.owner),
									x.segment_type,
									x.segment_name,
									x.size_mb,
									v_initial_space_used,
									v_space_current,
									v_space_future,
									v_pct_ocupation,
									sysdate);
				end if;
		else
		        if x.segment_type not like '%LOB%' then
				begin
				v_position_estimation:=0;
				for y in c_estimation(x.owner, x.segment_name, x.segment_type)
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
						values (x.owner,
								x.segment_name,
								x.segment_type,
								null,
								x.size_mb,
								v_initial_space_used,
								v_space_current,
								v_space_future,
								v_pct_ocupation,
								sysdate);
				
				end;
				end if;
		end if;
	end loop;
end;
/
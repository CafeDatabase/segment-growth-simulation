create or replace procedure CHECK_SEGMENT_GROWTH (p_owner varchar2)
as
    cursor c_segmentos is select owner, segment_name, substr(segment_type,1,30) segment_type from dba_segments where owner=p_owner;
    cursor c_estimacion (v_owner varchar2, v_segmento varchar2,v_tipo varchar2)
        is select * from table(dbms_space.OBJECT_GROWTH_TREND(v_owner,v_segmento,v_tipo)) order by timepoint,quality;
	v_posicion_estimacion number;
	v_espacio_usado_inicial number;
	v_espacio_actual number;
	v_espacio_futuro number;
	v_porcentaje_ocupado number;
begin
    DBMS_OUTPUT.ENABLE(1000000);
    for x in c_segmentos
	loop
	    DBMS_OUTPUT.PUT_LINE('v_owner:= '||x.owner||' v_segmento:= '||x.segment_name||' v_tipo:= '||x.segment_type);
		v_posicion_estimacion :=0;
	    v_espacio_usado_inicial  :=0;
	    v_espacio_actual  :=0;
	    v_espacio_futuro  :=0;
	    v_porcentaje_ocupado  :=0;
		if x.segment_type like '%PARTITION%' then
				v_posicion_estimacion:=0;
				for y in c_estimacion(x.owner, x.segment_name, x.segment_type)
				loop
						if v_posicion_estimacion=0 then
								v_espacio_usado_inicial:=y.space_usage;
								v_espacio_actual:=y.space_usage;
								v_espacio_futuro:=y.space_usage;
								v_porcentaje_ocupado:=round(y.space_usage/y.space_alloc,2)*100;
								v_posicion_estimacion:=1;
						end if;
						if trunc(y.timepoint)=trunc(systimestamp) then
								v_espacio_actual:=y.space_usage;
								v_porcentaje_ocupado:=round(y.space_usage/y.space_alloc,2)*100;
								v_posicion_estimacion:=2;
						end if;
						if v_posicion_estimacion=2 then
								v_espacio_futuro:=y.space_usage;
						end if;
				end loop;
				if x.segment_type like '%INDEX%' then
						insert into laboratorio.capacidad_tablas
							values (  x.owner,
									(select index_name from dba_ind_partitions where partition_name=x.segment_name and index_owner=x.owner),
									x.segment_type,
									x.segment_name,
									v_espacio_usado_inicial,
									v_espacio_actual,
									v_espacio_futuro,
									v_porcentaje_ocupado,
									sysdate);
				else 
						insert into laboratorio.capacidad_tablas
							values (  x.owner,
									(select table_name from dba_tab_partitions where partition_name=x.segment_name and table_owner=x.owner),
									x.segment_type,
									x.segment_name,
									v_espacio_usado_inicial,
									v_espacio_actual,
									v_espacio_futuro,
									v_porcentaje_ocupado,
									sysdate);
				end if;
		else
		        if x.segment_type not like '%LOB%' then
				begin
				v_posicion_estimacion:=0;
				for y in c_estimacion(x.owner, x.segment_name, x.segment_type)
				loop
						if v_posicion_estimacion=0 then
								v_espacio_usado_inicial:=y.space_usage;
								v_espacio_actual:=y.space_usage;
								v_espacio_futuro:=y.space_usage;
								v_porcentaje_ocupado:=round(y.space_usage/y.space_alloc,2)*100;
						v_posicion_estimacion:=1;
						end if;
						if trunc(y.timepoint)=trunc(systimestamp) then
								v_espacio_actual:=y.space_usage;
								v_porcentaje_ocupado:=round(y.space_usage/y.space_alloc,2)*100;
								v_posicion_estimacion:=2;
						end if;
						if v_posicion_estimacion=2 then
											v_espacio_futuro:=y.space_usage;
						end if;
				end loop;
				
				insert into laboratorio.capacidad_tablas
						values (x.owner,
								x.segment_name,
								x.segment_type,
								null,
								v_espacio_usado_inicial,
								v_espacio_actual,
								v_espacio_futuro,
								v_porcentaje_ocupado,
								sysdate);
				
				end;
				end if;
		end if;
	end loop;
end;
/




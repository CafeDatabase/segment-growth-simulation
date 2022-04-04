-- test of dbms_space.object_growth_trend in a PL/SQL block, for one table only screen output

set severoutput on

begin
  for x in (select * from table(dbms_space.OBJECT_GROWTH_TREND('HR','EMPLOYEES','TABLE')))
  loop
     dbms_output.put_line (x.TIMEPOINT||x.SPACE_USAGE||x.SPACE_ALLOC||x.QUALITY);
  end loop;
end;
/


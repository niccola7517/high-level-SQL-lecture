/* 1-3 */
select /*+ ordered use_nl(a b c d e) */ b.dept_name, c.emp_no, c.first_name||' '||c.last_name, c.gender, c.hire_date, d.title, e.salary
from dept_manager a, departments b, employees c, titles d, salaries e
where '20000101' between a.from_date and a.to_date
  and a.dept_no = b.dept_no
  and a.emp_no = c.emp_no
  and a.emp_no = d.emp_no and  '20000101' between d.from_date and d.to_date
  and a.emp_no = e.emp_no and  '20000101' between e.from_date and e.to_date ;
  
/* 2-4 */
select a.emp_no
      , a.birth_date, a.gender, a.hire_date
      , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.birth_date between to_date('19580501','yyyymmdd') and to_date('19580531','yyyymmdd')
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;
  
/* 3-3 */
select sum(cnt)
from ( select decode(b.no, 1, floor(a.no/10)), count(*) cnt
       from copy_t a, copy_t b
       where a.no <= 20 and b.no <= 2
       group by decode(b.no, 1, floor(a.no/10)) ) ;
       
/* 3-4 */
select nvl(y.dept_name, '합계') 부서명
     , x.title 직급명
     , x.cnt_emps 사원수
from ( select decode(grouping(b.dept_no), 1, '합계', b.dept_no) dept_no
            , decode(grouping(c.title), 1, '합계', c.title) title
            , count(*) cnt_emps
       from salaries a, dept_emp b, titles c
       where a.emp_no = b.emp_no
         and b.emp_no = c.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231' and c.to_date = '99991231'
       group by cube(b.dept_no, c.title) ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* 4-3 */
select sum(col1) + sum(col2)
from ( select no
            , sum(no) over (partition by mod(no, 2)) col1
            , sum(no) over (partition by mod(no, 2) order by rownum) col2
       from copy_t
       where no <= 5 ) ;

/* 4-4 */
create table copy_ymd (
  ymd varchar2(8) primary key,
  ymd_date date not null ) ;
  
insert into copy_ymd
select to_char(to_date('19000101','yyyymmdd')+rownum-1, 'yyyymmdd') 
     , to_date('19000101','yyyymmdd')+rownum-1
from employees
where rownum <= 100000 ;

commit ;

select ceil((rnum+start_yoil-1)/7) 주차
     , min(sun) 일
     , min(mon) 월
     , min(tue) 화
     , min(wed) 수
     , min(thu) 목
     , min(fri) 금
     , min(sat) 토   
from (
select decode(mod(yoil, 7), 1, day) sun
     , decode(mod(yoil, 7), 2, day) mon
     , decode(mod(yoil, 7), 3, day) tue
     , decode(mod(yoil, 7), 4, day) wed
     , decode(mod(yoil, 7), 5, day) thu
     , decode(mod(yoil, 7), 6, day) fri
     , decode(mod(yoil, 7), 0, day) sat
     , rownum rnum
from (
select trunc(substr(ymd, 7),'0') day
     , to_char(ymd_date, 'd') yoil
from copy_ymd
where ymd like :v_month||'%' )) a, ( select to_char(ymd_date, 'd') start_yoil
                                    from copy_ymd
                                    where ymd = :v_month||'01') b
group by ceil((rnum+start_yoil-1)/7)
order by 1 ;
       
/* 실습 8. (집계함수+문자열함수) 활용 / 그룹핑컬럼 가공 */
/* 8-1. 부서별 급여를 가장 많이 받는 사원의 이름(first_name+last_name)과 급여(salary) */
select a.dept_name
     , substr(max(lpad(d.salary, 6, '0')||c.first_name||' '||c.last_name), 7) emp_name
     , max(d.salary) salary
from departments a, dept_emp b, employees c, salaries d
where a.dept_no = b.dept_no and b.to_date = '99991231'
  and b.emp_no = c.emp_no
  and c.emp_no = d.emp_no and d.to_date = '99991231'
group by a.dept_name ;

/* 8-2. 현직 사원에 대한 입사연도별 급여 평균  */
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ substr(to_char(a.hire_date, 'yyyymmdd'), 1, 4) 입사연도
     , round(avg(b.salary)) 급여평균
from employees a, salaries b
where a.emp_no = b.emp_no
  and b.to_date = '99991231'
group by substr(to_char(a.hire_date, 'yyyymmdd'), 1, 4) ;


/* 실습 9. UNION ALL을 활용한 실행계획 분리 */
/* 9-1. 사원 이름으로 사원정보(성명, 연령, 입사일자, 소속부서명, 직급명, 급여) 검색 (first_name으로 찾기 / last_name으로 찾기) */
   
/* 9-1-1) 인덱스 생성 (first_name) */
create index employees_idx3 on employees (first_name) ;

/* 9-1-2) 비효율은 없을까? */
-- 예) first_name : Shigeu, last_name : Matzen
select a.first_name||' '||a.last_name emp_name
     , ceil((sysdate - birth_date) / 365) age
     , a.hire_date
     , c.dept_name
     , d.title
     , e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.first_name like :v_first_name||'%'
  and a.last_name like :v_last_name||'%' 
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;
  
/* 9-1-3) 실행계획 분리 ( first_name으로 검색하는 경우와 last_name으로 검색하는 경우를 분리하여 SQL 작성) */
select /*+ ordered use_nl(a b c d e) index(a employees_idx1) */ a.first_name||' '||a.last_name emp_name
     , ceil((sysdate - birth_date) / 365) age
     , a.hire_date
     , c.dept_name
     , d.title
     , e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where :v_gubun = 1  -- last_name으로 검색
  and a.last_name like :v_last_name||'%' 
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' 
union all
select /*+ ordered use_nl(a b c d e) index(a employees_idx3) */ a.first_name||' '||a.last_name emp_name
     , ceil((sysdate - birth_date) / 365) age
     , a.hire_date
     , c.dept_name
     , d.title
     , e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where :v_gubun = 2  -- first_name으로 검색
  and a.first_name like :v_first_name||'%'
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;

/* 실습 10. 부분합 / 데이터복제 / ROLLUP과 CUBE */
/* 10-1. 현재 부서별 사원들의 급여 합계와 급여 총합계 산출 (데이터복제를 활용한 부분합) */
/* 10-1-1) 복제 테이블 생성 */
create table copy_t (
  no number(2) not null,
  no2 varchar2(2) not null ) ;
  
/* 10-1-2) 복제 테이블 데이터 생성 */
insert into copy_t
select rownum
     , lpad(rownum,2,'0')
from employees
where rownum <= 99 ;  -- rownum : STOP KEY

commit ;

/* 10-1-3) 데이터복제를 통한 급여 부분합(엑셀 부분합과 유사) 산출 */ 
select nvl(y.dept_name, '합계') 부서명
     , x.sum_sal 급여합
from ( select decode(b.no, 1, a.dept_no, '합계') dept_no
            , sum(sum_sal) sum_sal
       from ( select b.dept_no
                   , sum(a.salary) sum_sal
              from salaries a, dept_emp b
              where a.emp_no = b.emp_no
                and a.to_date = '99991231' and b.to_date = '99991231'
              group by b.dept_no ) a, copy_t b
       where b.no <= 2
       group by no, decode(b.no, 1, a.dept_no, '합계') ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* 10-2. 현재 부서별 사원들의 급여 합계와 급여 총합계 산출 (rollup()을 활용한 부분합) */
select nvl(y.dept_name, '합계') 부서명
     , x.sum_sal 급여합
from ( select b.dept_no
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b
       where a.emp_no = b.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231'
       group by rollup(b.dept_no) ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* 10-3. 현재 부서별/직급별 급여합 및 전체 급여합 산출 (cube()를 활용한 부분합) */
select nvl(y.dept_name, '합계') 부서명
     , x.title 직급명
     , x.sum_sal 급여합
from ( select decode(grouping(b.dept_no), 1, '합계', b.dept_no) dept_no
            , decode(grouping(c.title), 1, '합계', c.title) title
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b, titles c
       where a.emp_no = b.emp_no
         and b.emp_no = c.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231' and c.to_date = '99991231'
       group by cube(b.dept_no, c.title) ) x, departments y
where x.dept_no = y.dept_no(+) ;
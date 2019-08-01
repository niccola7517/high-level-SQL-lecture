/* 실습 11. 분석함수(analytic function) */
-- 11-1. 각 사원의 급여와 소속부서 평균급여의 차이
SELECT
    성명,
    사원급여 - 소속부서평균급여 급여차이
FROM
    (
        SELECT
            a.first_name
            || ' '
            || a.last_name 성명,
            c.salary 사원급여,
            round(AVG(c.salary) OVER(
                PARTITION BY b.dept_no
            )) 소속부서평균급여
        FROM
            employees   a,
            dept_emp    b,
            salaries    c
        WHERE
            a.emp_no = b.emp_no
            AND b.TO_DATE = '99991231'
            AND a.emp_no = c.emp_no
            AND c.TO_DATE = '99991231'
    );

/* 11.2. 각 사원의 사번, 사원명, 입사일자, 급여변동일, 변동일당시급여, 급여인상액, 급여누적평균 */
select a.emp_no 사번
     , a.first_name||' '||a.last_name 성명
     , a.hire_date 입사일자
     , to_date(b.from_date, 'yyyymmdd') 급여변동일
     , b.salary 변동일당시급여
     , b.salary - lag(b.salary) over (partition by b.emp_no order by b.from_date) 급여인상액
     , round(avg(b.salary) over (partition by b.emp_no order by b.from_date)) 급여누적평균    
from employees a, salaries b
where a.emp_no = b.emp_no ;

/* 실습 12. 행/열 전환(pivoting) */
/* 12-1. 직급별 사원수 산출 (행->열) 전환 */
/* 12-1-1) 직급별 사원수 산출을 위한 view 생성 */
create or replace view v_title_emp_rows
as
select title
     , count(*) cnt_emp
from titles
where to_date = '99991231'  -- 현재 기준
group by title ;

select * from v_title_emp_rows ;

/* 12-1-2) 직급에 대한 (행->열) 전환 */
select '사원수' 항목명
     , min(decode(title, 'Manager', cnt_emp)) Manager
     , min(decode(title, 'Technique Leader', cnt_emp)) Technique_Leader
     , min(decode(title, 'Senior Engineer', cnt_emp)) Senior_Engineer
     , min(decode(title, 'Engineer', cnt_emp)) Engineer
     , min(decode(title, 'Assistant Engineer', cnt_emp)) Assistant_Engineer
     , min(decode(title, 'Senior Staff', cnt_emp)) Senior_Staff
     , min(decode(title, 'Staff', cnt_emp)) Staff
from v_title_emp_rows ;

/* 12-2. 직급별 사원수 산출 (열->행) 전환 */
/* 12-2-1) 직급별 사원수 산출을 위한 view 생성 (12-1-1번 SQL을 view로 생성) */
create or replace view v_title_emp_columns
as
select '사원수' 항목명
     , min(decode(title, 'Manager', cnt_emp)) Manager
     , min(decode(title, 'Technique Leader', cnt_emp)) Technique_Leader
     , min(decode(title, 'Senior Engineer', cnt_emp)) Senior_Engineer
     , min(decode(title, 'Engineer', cnt_emp)) Engineer
     , min(decode(title, 'Assistant Engineer', cnt_emp)) Assistant_Engineer
     , min(decode(title, 'Senior Staff', cnt_emp)) Senior_Staff
     , min(decode(title, 'Staff', cnt_emp)) Staff
from v_title_emp_rows ;

select * from v_title_emp_columns ;

/* 12-2-2) 직급에 대한 (열->행) 전환 */
select decode(no, 1, 'Manager'
                , 2, 'Technique Leader'
                , 3, 'Senior Engineer'
                , 4, 'Engineer'
                , 5, 'Assistant Engineer'
                , 6, 'Senior Staff'
                , 'Staff') title
     , decode(no, 1, Manager
                , 2, Technique_Leader
                , 3, Senior_Engineer
                , 4, Engineer
                , 5, Assistant_Engineer
                , 6, Senior_Staff
                , Staff) cnt_emp                
from v_title_emp_columns a, copy_t b
where b.no <= 7 ;

/* 12-2-3) With문 이용하기 (12-2-1번과 12-2-2번을 합쳐서 표현) */
with title_emp_columns as
(select '사원수' 항목명
     , min(decode(title, 'Manager', cnt_emp)) Manager
     , min(decode(title, 'Technique Leader', cnt_emp)) Technique_Leader
     , min(decode(title, 'Senior Engineer', cnt_emp)) Senior_Engineer
     , min(decode(title, 'Engineer', cnt_emp)) Engineer
     , min(decode(title, 'Assistant Engineer', cnt_emp)) Assistant_Engineer
     , min(decode(title, 'Senior Staff', cnt_emp)) Senior_Staff
     , min(decode(title, 'Staff', cnt_emp)) Staff
from v_title_emp_rows)
select decode(no, 1, 'Manager'
                , 2, 'Technique Leader'
                , 3, 'Senior Engineer'
                , 4, 'Engineer'
                , 5, 'Assistant Engineer'
                , 6, 'Senior Staff'
                , 'Staff') title
     , decode(no, 1, Manager
                , 2, Technique_Leader
                , 3, Senior_Engineer
                , 4, Engineer
                , 5, Assistant_Engineer
                , 6, Senior_Staff
                , Staff) cnt_emp                
from title_emp_columns a, copy_t b
where b.no <= 7 ;

/* 12-3. 10-3번 예에 대한 (행->열) 전환 */
/* 12-3-1) 부서별/직급별 급여합에 대한 view 생성 (10-3번 SQL을 view로 생성) */
create or replace view v_dept_title_salaries
as
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

select * from v_dept_title_salaries ;

/* 12-3-2) 직급에 대한 (행->열) 전환 */
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ 부서명
     , min(decode(직급명, 'Assistant Engineer', 급여합)) "Assitant Engineer"
     , min(decode(직급명, 'Engineer', 급여합)) "Engineer"
     , min(decode(직급명, 'Senior Engineer', 급여합)) "Senior Engineer"
     , min(decode(직급명, 'Staff', 급여합)) "Staff"
     , min(decode(직급명, 'Senior Staff', 급여합)) "Senior Staff"
     , min(decode(직급명, 'Technique Leader', 급여합)) "Technique Leader"
     , min(decode(직급명, 'Manager', 급여합)) "Manager"
     , min(decode(직급명, '합계', 급여합)) "합계"
from v_dept_title_salaries
group by 부서명 ;

/* 12-2-3) With문 이용하기 (12-3-1번과 12-3-2번을 합쳐서 표현) */
with v_dept_title_salaries as
(select nvl(y.dept_name, '합계') 부서명
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
where x.dept_no = y.dept_no(+))
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ 부서명
     , min(decode(직급명, 'Assistant Engineer', 급여합)) "Assitant Engineer"
     , min(decode(직급명, 'Engineer', 급여합)) "Engineer"
     , min(decode(직급명, 'Senior Engineer', 급여합)) "Senior Engineer"
     , min(decode(직급명, 'Staff', 급여합)) "Staff"
     , min(decode(직급명, 'Senior Staff', 급여합)) "Senior Staff"
     , min(decode(직급명, 'Technique Leader', 급여합)) "Technique Leader"
     , min(decode(직급명, 'Manager', 급여합)) "Manager"
     , min(decode(직급명, '합계', 급여합)) "합계"
from v_dept_title_salaries
group by 부서명 ;
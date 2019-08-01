/* 실습 2. 예제 테이블 생성 */
DROP TABLE employees CASCADE CONSTRAINTS ;

CREATE TABLE employees (
    emp_no      NUMBER(6),
    birth_date  DATE         NOT NULL,
    first_name  VARCHAR2(30) NOT NULL,
    last_name   VARCHAR2(30) NOT NULL,
    gender      VARCHAR2(1)  NOT NULL,    
    hire_date   DATE            NOT NULL,
    CONSTRAINTS EMPLOYEES_PK PRIMARY KEY (emp_no),
    CONSTRAINTS GENDER_CK CHECK (gender in ('M', 'F'))
);

DROP TABLE departments CASCADE CONSTRAINTS ;

CREATE TABLE departments (
    dept_no     VARCHAR2(4),
    dept_name   VARCHAR2(40)     NOT NULL,
    CONSTRAINTS DEPARTMENTS_PK PRIMARY KEY (dept_no),
    CONSTRAINTS DEPARTMENTS_UK1 UNIQUE (dept_name)
);

DROP TABLE dept_manager CASCADE CONSTRAINTS ;

CREATE TABLE dept_manager (
   emp_no       NUMBER(6),
   dept_no      VARCHAR2(4)         NOT NULL,
   to_date      VARCHAR2(10)         NOT NULL,   
   from_date    VARCHAR2(10)         NOT NULL,
   CONSTRAINTS DEPT_MANAGER_PK PRIMARY KEY (dept_no, to_date),   
   CONSTRAINTS DEPT_MANAGER_FK1 FOREIGN KEY (emp_no)  REFERENCES employees (emp_no)    ON DELETE CASCADE,
   CONSTRAINTS DEPT_MANAGER_FK2 FOREIGN KEY (dept_no) REFERENCES departments (dept_no) ON DELETE CASCADE
); 

DROP TABLE dept_emp CASCADE CONSTRAINTS ;

CREATE TABLE dept_emp (
    emp_no      NUMBER(6),
    dept_no     VARCHAR2(4)     NOT NULL,
    to_date     VARCHAR2(10)     NOT NULL,    
    from_date   VARCHAR2(10)     NOT NULL,
    -- CONSTRAINTS DEPT_EMP_PK PRIMARY KEY (emp_no, to_date),
    CONSTRAINTS DEPT_EMP_FK1 FOREIGN KEY (emp_no)  REFERENCES employees   (emp_no)  ON DELETE CASCADE,
    CONSTRAINTS DEPT_EMP_FK2 FOREIGN KEY (dept_no) REFERENCES departments (dept_no) ON DELETE CASCADE
);

DROP TABLE titles CASCADE CONSTRAINTS ;

CREATE TABLE titles (
    emp_no      NUMBER(6)       NOT NULL,
    to_date     VARCHAR2(10)     NOT NULL,    
    from_date   VARCHAR2(10)     NOT NULL,
    title       VARCHAR2(50)    NOT NULL 
    -- CONSTRAINTS TITLES_PK PRIMARY KEY (emp_no, to_date),    
    -- CONSTRAINTS TITLES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE
); 

DROP TABLE salaries CASCADE CONSTRAINTS ;

CREATE TABLE salaries (
    emp_no      NUMBER(6)             NOT NULL,
    to_date     VARCHAR2(10)           NOT NULL,    
    from_date   VARCHAR2(10)           NOT NULL,
    salary      NUMBER(7)             NOT NULL
    --CONSTRAINTS SALARIES_PK PRIMARY KEY (emp_no, to_date),    
    --CONSTRAINTS SALARIES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE
); 
      
select count(*) from employees ;

select count(*) from departments ;

select count(*) from dept_manager ;

select count(*) from dept_emp ;

select count(*) from titles ;

select count(*) from salaries ;

/* 실습 4. 데이터 정제(data cleansing) */
/* 4-1. 사원이 동시에 2개 부서에 소속된 이력 중 하나 제거 */
/* 4-1-1) 동시에 두개 부서에 소속된 사원 현황 */
select *
from dept_emp
where (emp_no, from_date) in ( select emp_no
                                   , from_date
                              from dept_emp
                              group by emp_no, from_date
                              having count(*) > 1 ) ;
                              
-- 4-1-2) 중복 이력 중 하나만 선택하고 나머지 삭제 (cleansing rule : to_date가 가장 큰 것 선택)                              
delete
from dept_emp
where (emp_no, from_date, to_date) in ( select emp_no, from_date, to_date
                                        from dept_emp
                                        where (emp_no, from_date) in ( select emp_no
                                                                            , from_date
                                                                       from dept_emp
                                                                       group by emp_no, from_date
                                                                       having count(*) > 1 )
                                        minus
                                        select emp_no, from_date, to_date
                                        from dept_emp
                                        where (emp_no, to_date)
                                             in ( select emp_no, max(to_date)
                                                  from dept_emp
                                                  where (emp_no, from_date) in ( select emp_no
                                                                                      , from_date
                                                                                 from dept_emp
                                                                                 group by emp_no, from_date
                                                                                 having count(*) > 1 )
                                                  group by emp_no )) ;
                                                  
commit ;                                                  

-- 4-1-3) data cleansing 후 PK 제약조건 add (# 데이터 이관 시 제약조건 전략)
ALTER TABLE dept_emp ADD CONSTRAINTS DEPT_EMP_PK PRIMARY KEY (emp_no, to_date) ;

/* 4-2. 이력 날짜 8자리로 맞추기 */
update dept_manager
set from_date = substr(from_date, 1, 4)||substr(from_date, 6, 2)||substr(from_date, 9, 2) 
  , to_date = substr(to_date, 1, 4)||substr(to_date, 6, 2)||substr(to_date, 9, 2) ;
  
update dept_emp
set from_date = substr(from_date, 1, 4)||substr(from_date, 6, 2)||substr(from_date, 9, 2) 
  , to_date = substr(to_date, 1, 4)||substr(to_date, 6, 2)||substr(to_date, 9, 2) ;
  
update titles
set from_date = substr(from_date, 1, 4)||substr(from_date, 6, 2)||substr(from_date, 9, 2) 
  , to_date = substr(to_date, 1, 4)||substr(to_date, 6, 2)||substr(to_date, 9, 2) ;
  
update salaries
set from_date = substr(from_date, 1, 4)||substr(from_date, 6, 2)||substr(from_date, 9, 2) 
  , to_date = substr(to_date, 1, 4)||substr(to_date, 6, 2)||substr(to_date, 9, 2) ;

commit ;

/* 4-2-1) rollback segments의 확장 */
-- rollback segments에 관련된 tablespace와 data file 및 사이즈 조회 (system 사용자로 로그인 후)
select file_name, tablespace_name, bytes from dba_data_files ;

-- rollback segments에 관련된 data file size-up
ALTER DATABASE DATAFILE 'C:\ORACLEXE\APP\ORACLE\ORADATA\XE\UNDOTBS1.DBF' RESIZE 100M;

/* 4-2-2) 컬럼 resize */
alter table dept_manager modify to_date varchar2(8) ;
alter table dept_manager modify from_date varchar2(8) ;

alter table dept_emp modify to_date varchar2(8) ;
alter table dept_emp modify from_date varchar2(8) ;

alter table titles modify to_date varchar2(8) ;
alter table titles modify from_date varchar2(8) ;

alter table salaries modify to_date varchar2(8) ;
alter table salaries modify from_date varchar2(8) ;

/* 4-3. 현재 상태의 종료일자(to_date) : '99990101 -> 99991231'로 변경 */
update dept_manager
set to_date = '99991231'
where to_date = '99990101' ;

update dept_emp
set to_date = '99991231'
where to_date = '99990101' ;

update titles
set to_date = '99991231'
where to_date = '99990101' ;

update salaries
set to_date = '99991231'
where to_date = '99990101' ;

commit ;

/* 4-4. 이력 관리 : 양편 넣기 -> 한편 넣기 (#이력관리기법) */
/* 4-4-1) cleansing rule : to_date 컬럼값이 '99991231'이 아닌 투플을 대상으로 to_date를 하루 앞 당기게 수정 */
update dept_manager
set to_date = to_char(to_date(to_date,'yyyymmdd') - 1, 'yyyymmdd')
where to_date <> '99991231' ;

update dept_emp
set to_date = to_char(to_date(to_date,'yyyymmdd') - 1, 'yyyymmdd')
where to_date <> '99991231' ;

update titles
set to_date = to_char(to_date(to_date,'yyyymmdd') - 1, 'yyyymmdd')
where to_date <> '99991231' ;

update salaries
set to_date = to_char(to_date(to_date,'yyyymmdd') - 1, 'yyyymmdd')
where to_date <> '99991231' ;

commit ;

/* 4-4-2) cleansing rule : 1)번 cleansing으로 인해 'to_date < from_date'인 튜플에 대해서 to_date를 from_date로 update */
update dept_manager
set to_date = from_date
where to_date < from_date ;

update dept_emp
set to_date = from_date
where to_date < from_date ;

update titles
set to_date = from_date
where to_date < from_date ;

update salaries
set to_date = from_date
where to_date < from_date ;

commit ;

/* 4-4-3) data cleansing 후 PK/FK 제약조건 add (# 데이터 이관 시 제약조건 전략) */
ALTER TABLE titles ADD CONSTRAINTS TITLES_PK PRIMARY KEY (emp_no, to_date) ;
ALTER TABLE titles ADD CONSTRAINTS TITLES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE ;

ALTER TABLE salaries ADD CONSTRAINTS SALARIES_PK PRIMARY KEY (emp_no, to_date) ;
ALTER TABLE salaries ADD CONSTRAINTS SALARIES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE ;

/* 실습 5. 이력 조회 */
/* 5-1. 부서별 현재 부서장의 사번(emp_no), 이름(first_name+last_name), 성별(gender), 입사일(hire_date), 직급(title), 급여(salary) */
select /*+ ordered use_nl(a b c d e) */ b.dept_name, c.emp_no, c.first_name||' '||c.last_name, c.gender, c.hire_date, d.title, e.salary
from dept_manager a, departments b, employees c, titles d, salaries e
where a.to_date = '99991231'
  and a.dept_no = b.dept_no
  and a.emp_no = c.emp_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ; 

/* 5-2. 'Lein Bale' 사원의 2000년 1월 1일 당시 소속부서, 직급, 급여 출력 */
/* 5-2-1) 조인 이용 */
select a.first_name, a.last_name
     , e.dept_name
     , c.title
     , d.salary
from employees a, dept_emp b, titles c, salaries d, departments e
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and '20000101' between b.from_date and b.to_date
  and a.emp_no = c.emp_no and '20000101' between c.from_date and c.to_date
  and a.emp_no = d.emp_no and '20000101' between d.from_date and d.to_date
  and b.dept_no = e.dept_no ;
  
/* 5-2-2) 스칼라 서브쿼리 이용 */
select a.first_name, a.last_name
     , (select dept_name from departments c where c.dept_no = b.dept_no) dept_name 
     , (select title from titles d where d.emp_no = a.emp_no 
                                    and '20000101' between d.from_date and d.to_date) title
     , (select salary from salaries e where e.emp_no = a.emp_no 
                                    and '20000101' between e.from_date and e.to_date) salary
from employees a, dept_emp b
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and '20000101' between b.from_date and b.to_date ;
  
/* 5-2-3) 5-2-2) SQL의 개선 : 어떤 면에서의 개선일까? */
select a.first_name, a.last_name
     , (select min(dept_name) from departments c where c.dept_no = b.dept_no) dept_name 
     , (select min(title) from titles d where d.emp_no = a.emp_no 
                                    and '20000101' between d.from_date and d.to_date) title
     , (select min(salary) from salaries e where e.emp_no = a.emp_no 
                                    and '20000101' between e.from_date and e.to_date) salary
from employees a, dept_emp b
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and '20000101' between b.from_date and b.to_date ;

/* 실습 6. 인덱스(index) / 조인(join) / 힌트(hint) */
/* 6-1. 'Lein Bale' 사원의 사번(emp_no), 생년월일(birth_date), 성별(gender), 고용일(hire_date), 소속부서명(dept_name), 
 직급(title), 급여(salary) 조회 (#인덱스 활용) */

/* 6-1-1) 무엇이 잘못되었을까? */
select *
from employees
where first_name||' '||last_name = 'Lein Bale' ; 

/* 6-1-2) 인덱스 생성(last_name) */
create index employees_idx1 on employees(last_name) ; 

/* 6-1-3) 1)번 SQL 튜닝 (실행계획과 수행시간 비교) */
select *
from employees
where first_name = 'Lein'
  and last_name = 'Bale' ; 

/* 6-1-4) 조인을 통해 여러 테이블에 산재된 컬럼값 출력 */
-- 실행계획을 통해 조인(join) 방식 확인 (#조인방식, #인덱스, #힌트)
select /*+ ordered use_nl(a b c d e) index(a employees_idx1) */ a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ; 
  
/* 6-2. 1999년도에 입사한 사원의 사번(emp_no), 생년월일(birth_date), 성별(gender), 고용일(hire_date), 소속부서명(dept_name), 
 직급(title), 급여(salary) 조회 (#인덱스 활용) */

-- 6-2-1) 답은 맞는거 같은데... 튜닝포인트는 없을까? 
select a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where to_char(a.hire_date,'yyyymmdd') between '19990101' and '19991231' 
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;
  
-- 6-2-2) 인덱스 생성(hire_date)
create index employees_idx2 on employees(hire_date) ; 

-- 6-2-3) 1)번 SQL 튜닝
select /*+ ordered use_nl(a b c d e) index(a employees_idx2) */ a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.hire_date between to_date('19990101', 'yyyymmdd') and to_date('19991231', 'yyyymmdd')
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;


/* 실습 7. 재귀적 관계의 처리 (#recursive relationship #start with...connect by) */  
/* 7-1. sample table 생성 */
CREATE TABLE EMP
       (EMPNO NUMBER(4) CONSTRAINT EMP_PK PRIMARY KEY,
	ENAME VARCHAR2(10),
	JOB VARCHAR2(9),
	MGR NUMBER(4),
	HIREDATE DATE,
	SAL NUMBER(7,2),
	COMM NUMBER(7,2),
	DEPTNO NUMBER(2));

/* 7-2. sample data 생성 */    
INSERT INTO EMP VALUES
(7369,'SMITH','CLERK',7902,to_date('17-12-1980','dd-mm-yyyy'),800,NULL,20);
INSERT INTO EMP VALUES
(7499,'ALLEN','SALESMAN',7698,to_date('20-2-1981','dd-mm-yyyy'),1600,300,30);
INSERT INTO EMP VALUES
(7521,'WARD','SALESMAN',7698,to_date('22-2-1981','dd-mm-yyyy'),1250,500,30);
INSERT INTO EMP VALUES
(7566,'JONES','MANAGER',7839,to_date('2-4-1981','dd-mm-yyyy'),2975,NULL,20);
INSERT INTO EMP VALUES
(7654,'MARTIN','SALESMAN',7698,to_date('28-9-1981','dd-mm-yyyy'),1250,1400,30);
INSERT INTO EMP VALUES
(7698,'BLAKE','MANAGER',7839,to_date('1-5-1981','dd-mm-yyyy'),2850,NULL,30);
INSERT INTO EMP VALUES
(7782,'CLARK','MANAGER',7839,to_date('9-6-1981','dd-mm-yyyy'),2450,NULL,10);
INSERT INTO EMP VALUES
(7788,'SCOTT','ANALYST',7566,to_date('13-JUL-87')-85,3000,NULL,20);
INSERT INTO EMP VALUES
(7839,'KING','PRESIDENT',NULL,to_date('17-11-1981','dd-mm-yyyy'),5000,NULL,10);
INSERT INTO EMP VALUES
(7844,'TURNER','SALESMAN',7698,to_date('8-9-1981','dd-mm-yyyy'),1500,0,30);
INSERT INTO EMP VALUES
(7876,'ADAMS','CLERK',7788,to_date('13-JUL-87')-51,1100,NULL,20);
INSERT INTO EMP VALUES
(7900,'JAMES','CLERK',7698,to_date('3-12-1981','dd-mm-yyyy'),950,NULL,30);
INSERT INTO EMP VALUES
(7902,'FORD','ANALYST',7566,to_date('3-12-1981','dd-mm-yyyy'),3000,NULL,20);
INSERT INTO EMP VALUES
(7934,'MILLER','CLERK',7782,to_date('23-1-1982','dd-mm-yyyy'),1300,NULL,10); 

/* 7-3. emp 테이블에서 사원 간 상하관계 출력 */
select lpad(' ', 2*level)||ename||'('||job||')' as "조직도"
from emp
start with mgr is null
connect by prior empno = mgr ;

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









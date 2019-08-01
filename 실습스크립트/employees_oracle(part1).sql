/* �ǽ� 2. ���� ���̺� ���� */
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

/* �ǽ� 4. ������ ����(data cleansing) */
/* 4-1. ����� ���ÿ� 2�� �μ��� �Ҽӵ� �̷� �� �ϳ� ���� */
/* 4-1-1) ���ÿ� �ΰ� �μ��� �Ҽӵ� ��� ��Ȳ */
select *
from dept_emp
where (emp_no, from_date) in ( select emp_no
                                   , from_date
                              from dept_emp
                              group by emp_no, from_date
                              having count(*) > 1 ) ;
                              
-- 4-1-2) �ߺ� �̷� �� �ϳ��� �����ϰ� ������ ���� (cleansing rule : to_date�� ���� ū �� ����)                              
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

-- 4-1-3) data cleansing �� PK �������� add (# ������ �̰� �� �������� ����)
ALTER TABLE dept_emp ADD CONSTRAINTS DEPT_EMP_PK PRIMARY KEY (emp_no, to_date) ;

/* 4-2. �̷� ��¥ 8�ڸ��� ���߱� */
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

/* 4-2-1) rollback segments�� Ȯ�� */
-- rollback segments�� ���õ� tablespace�� data file �� ������ ��ȸ (system ����ڷ� �α��� ��)
select file_name, tablespace_name, bytes from dba_data_files ;

-- rollback segments�� ���õ� data file size-up
ALTER DATABASE DATAFILE 'C:\ORACLEXE\APP\ORACLE\ORADATA\XE\UNDOTBS1.DBF' RESIZE 100M;

/* 4-2-2) �÷� resize */
alter table dept_manager modify to_date varchar2(8) ;
alter table dept_manager modify from_date varchar2(8) ;

alter table dept_emp modify to_date varchar2(8) ;
alter table dept_emp modify from_date varchar2(8) ;

alter table titles modify to_date varchar2(8) ;
alter table titles modify from_date varchar2(8) ;

alter table salaries modify to_date varchar2(8) ;
alter table salaries modify from_date varchar2(8) ;

/* 4-3. ���� ������ ��������(to_date) : '99990101 -> 99991231'�� ���� */
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

/* 4-4. �̷� ���� : ���� �ֱ� -> ���� �ֱ� (#�̷°������) */
/* 4-4-1) cleansing rule : to_date �÷����� '99991231'�� �ƴ� ������ ������� to_date�� �Ϸ� �� ���� ���� */
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

/* 4-4-2) cleansing rule : 1)�� cleansing���� ���� 'to_date < from_date'�� Ʃ�ÿ� ���ؼ� to_date�� from_date�� update */
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

/* 4-4-3) data cleansing �� PK/FK �������� add (# ������ �̰� �� �������� ����) */
ALTER TABLE titles ADD CONSTRAINTS TITLES_PK PRIMARY KEY (emp_no, to_date) ;
ALTER TABLE titles ADD CONSTRAINTS TITLES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE ;

ALTER TABLE salaries ADD CONSTRAINTS SALARIES_PK PRIMARY KEY (emp_no, to_date) ;
ALTER TABLE salaries ADD CONSTRAINTS SALARIES_FK1 FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE ;

/* �ǽ� 5. �̷� ��ȸ */
/* 5-1. �μ��� ���� �μ����� ���(emp_no), �̸�(first_name+last_name), ����(gender), �Ի���(hire_date), ����(title), �޿�(salary) */
select /*+ ordered use_nl(a b c d e) */ b.dept_name, c.emp_no, c.first_name||' '||c.last_name, c.gender, c.hire_date, d.title, e.salary
from dept_manager a, departments b, employees c, titles d, salaries e
where a.to_date = '99991231'
  and a.dept_no = b.dept_no
  and a.emp_no = c.emp_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ; 

/* 5-2. 'Lein Bale' ����� 2000�� 1�� 1�� ��� �ҼӺμ�, ����, �޿� ��� */
/* 5-2-1) ���� �̿� */
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
  
/* 5-2-2) ��Į�� �������� �̿� */
select a.first_name, a.last_name
     , (select dept_name from departments c where c.dept_no = b.dept_no) dept_name 
     , (select title from titles d where d.emp_no = a.emp_no 
                                    and '20000101' between d.from_date and d.to_date) title
     , (select salary from salaries e where e.emp_no = a.emp_no 
                                    and '20000101' between e.from_date and e.to_date) salary
from employees a, dept_emp b
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and '20000101' between b.from_date and b.to_date ;
  
/* 5-2-3) 5-2-2) SQL�� ���� : � �鿡���� �����ϱ�? */
select a.first_name, a.last_name
     , (select min(dept_name) from departments c where c.dept_no = b.dept_no) dept_name 
     , (select min(title) from titles d where d.emp_no = a.emp_no 
                                    and '20000101' between d.from_date and d.to_date) title
     , (select min(salary) from salaries e where e.emp_no = a.emp_no 
                                    and '20000101' between e.from_date and e.to_date) salary
from employees a, dept_emp b
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and '20000101' between b.from_date and b.to_date ;









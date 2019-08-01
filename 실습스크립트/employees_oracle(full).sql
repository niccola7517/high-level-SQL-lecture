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

/* �ǽ� 6. �ε���(index) / ����(join) / ��Ʈ(hint) */
/* 6-1. 'Lein Bale' ����� ���(emp_no), �������(birth_date), ����(gender), �����(hire_date), �ҼӺμ���(dept_name), 
 ����(title), �޿�(salary) ��ȸ (#�ε��� Ȱ��) */

/* 6-1-1) ������ �߸��Ǿ�����? */
select *
from employees
where first_name||' '||last_name = 'Lein Bale' ; 

/* 6-1-2) �ε��� ����(last_name) */
create index employees_idx1 on employees(last_name) ; 

/* 6-1-3) 1)�� SQL Ʃ�� (�����ȹ�� ����ð� ��) */
select *
from employees
where first_name = 'Lein'
  and last_name = 'Bale' ; 

/* 6-1-4) ������ ���� ���� ���̺� ����� �÷��� ��� */
-- �����ȹ�� ���� ����(join) ��� Ȯ�� (#���ι��, #�ε���, #��Ʈ)
select /*+ ordered use_nl(a b c d e) index(a employees_idx1) */ a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.first_name = 'Lein' and a.last_name = 'Bale'
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ; 
  
/* 6-2. 1999�⵵�� �Ի��� ����� ���(emp_no), �������(birth_date), ����(gender), �����(hire_date), �ҼӺμ���(dept_name), 
 ����(title), �޿�(salary) ��ȸ (#�ε��� Ȱ��) */

-- 6-2-1) ���� �´°� ������... Ʃ������Ʈ�� ������? 
select a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where to_char(a.hire_date,'yyyymmdd') between '19990101' and '19991231' 
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;
  
-- 6-2-2) �ε��� ����(hire_date)
create index employees_idx2 on employees(hire_date) ; 

-- 6-2-3) 1)�� SQL Ʃ��
select /*+ ordered use_nl(a b c d e) index(a employees_idx2) */ a.emp_no
     , a.birth_date, a.gender, a.hire_date
     , c.dept_name, d.title, e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where a.hire_date between to_date('19990101', 'yyyymmdd') and to_date('19991231', 'yyyymmdd')
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;


/* �ǽ� 7. ����� ������ ó�� (#recursive relationship #start with...connect by) */  
/* 7-1. sample table ���� */
CREATE TABLE EMP
       (EMPNO NUMBER(4) CONSTRAINT EMP_PK PRIMARY KEY,
	ENAME VARCHAR2(10),
	JOB VARCHAR2(9),
	MGR NUMBER(4),
	HIREDATE DATE,
	SAL NUMBER(7,2),
	COMM NUMBER(7,2),
	DEPTNO NUMBER(2));

/* 7-2. sample data ���� */    
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

/* 7-3. emp ���̺��� ��� �� ���ϰ��� ��� */
select lpad(' ', 2*level)||ename||'('||job||')' as "������"
from emp
start with mgr is null
connect by prior empno = mgr ;

/* �ǽ� 8. (�����Լ�+���ڿ��Լ�) Ȱ�� / �׷����÷� ���� */
/* 8-1. �μ��� �޿��� ���� ���� �޴� ����� �̸�(first_name+last_name)�� �޿�(salary) */
select a.dept_name
     , substr(max(lpad(d.salary, 6, '0')||c.first_name||' '||c.last_name), 7) emp_name
     , max(d.salary) salary
from departments a, dept_emp b, employees c, salaries d
where a.dept_no = b.dept_no and b.to_date = '99991231'
  and b.emp_no = c.emp_no
  and c.emp_no = d.emp_no and d.to_date = '99991231'
group by a.dept_name ;

/* 8-2. ���� ����� ���� �Ի翬���� �޿� ���  */
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ substr(to_char(a.hire_date, 'yyyymmdd'), 1, 4) �Ի翬��
     , round(avg(b.salary)) �޿����
from employees a, salaries b
where a.emp_no = b.emp_no
  and b.to_date = '99991231'
group by substr(to_char(a.hire_date, 'yyyymmdd'), 1, 4) ;


/* �ǽ� 9. UNION ALL�� Ȱ���� �����ȹ �и� */
/* 9-1. ��� �̸����� �������(����, ����, �Ի�����, �ҼӺμ���, ���޸�, �޿�) �˻� (first_name���� ã�� / last_name���� ã��) */
   
/* 9-1-1) �ε��� ���� (first_name) */
create index employees_idx3 on employees (first_name) ;

/* 9-1-2) ��ȿ���� ������? */
-- ��) first_name : Shigeu, last_name : Matzen
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
  
/* 9-1-3) �����ȹ �и� ( first_name���� �˻��ϴ� ���� last_name���� �˻��ϴ� ��츦 �и��Ͽ� SQL �ۼ�) */
select /*+ ordered use_nl(a b c d e) index(a employees_idx1) */ a.first_name||' '||a.last_name emp_name
     , ceil((sysdate - birth_date) / 365) age
     , a.hire_date
     , c.dept_name
     , d.title
     , e.salary
from employees a, dept_emp b, departments c, titles d, salaries e
where :v_gubun = 1  -- last_name���� �˻�
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
where :v_gubun = 2  -- first_name���� �˻�
  and a.first_name like :v_first_name||'%'
  and a.emp_no = b.emp_no and b.to_date = '99991231'
  and b.dept_no = c.dept_no
  and a.emp_no = d.emp_no and d.to_date = '99991231'
  and a.emp_no = e.emp_no and e.to_date = '99991231' ;

/* �ǽ� 10. �κ��� / �����ͺ��� / ROLLUP�� CUBE */
/* 10-1. ���� �μ��� ������� �޿� �հ�� �޿� ���հ� ���� (�����ͺ����� Ȱ���� �κ���) */
/* 10-1-1) ���� ���̺� ���� */
create table copy_t (
  no number(2) not null,
  no2 varchar2(2) not null ) ;
  
/* 10-1-2) ���� ���̺� ������ ���� */
insert into copy_t
select rownum
     , lpad(rownum,2,'0')
from employees
where rownum <= 99 ;  -- rownum : STOP KEY

commit ;

/* 10-1-3) �����ͺ����� ���� �޿� �κ���(���� �κ��հ� ����) ���� */ 
select nvl(y.dept_name, '�հ�') �μ���
     , x.sum_sal �޿���
from ( select decode(b.no, 1, a.dept_no, '�հ�') dept_no
            , sum(sum_sal) sum_sal
       from ( select b.dept_no
                   , sum(a.salary) sum_sal
              from salaries a, dept_emp b
              where a.emp_no = b.emp_no
                and a.to_date = '99991231' and b.to_date = '99991231'
              group by b.dept_no ) a, copy_t b
       where b.no <= 2
       group by no, decode(b.no, 1, a.dept_no, '�հ�') ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* 10-2. ���� �μ��� ������� �޿� �հ�� �޿� ���հ� ���� (rollup()�� Ȱ���� �κ���) */
select nvl(y.dept_name, '�հ�') �μ���
     , x.sum_sal �޿���
from ( select b.dept_no
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b
       where a.emp_no = b.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231'
       group by rollup(b.dept_no) ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* 10-3. ���� �μ���/���޺� �޿��� �� ��ü �޿��� ���� (cube()�� Ȱ���� �κ���) */
select nvl(y.dept_name, '�հ�') �μ���
     , x.title ���޸�
     , x.sum_sal �޿���
from ( select decode(grouping(b.dept_no), 1, '�հ�', b.dept_no) dept_no
            , decode(grouping(c.title), 1, '�հ�', c.title) title
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b, titles c
       where a.emp_no = b.emp_no
         and b.emp_no = c.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231' and c.to_date = '99991231'
       group by cube(b.dept_no, c.title) ) x, departments y
where x.dept_no = y.dept_no(+) ;

/* �ǽ� 11. �м��Լ�(analytic function) */
-- 11-1. �� ����� �޿��� �ҼӺμ� ��ձ޿��� ����
SELECT
    ����,
    ����޿� - �ҼӺμ���ձ޿� �޿�����
FROM
    (
        SELECT
            a.first_name
            || ' '
            || a.last_name ����,
            c.salary ����޿�,
            round(AVG(c.salary) OVER(
                PARTITION BY b.dept_no
            )) �ҼӺμ���ձ޿�
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

/* 11.2. �� ����� ���, �����, �Ի�����, �޿�������, �����ϴ�ñ޿�, �޿��λ��, �޿�������� */
select a.emp_no ���
     , a.first_name||' '||a.last_name ����
     , a.hire_date �Ի�����
     , to_date(b.from_date, 'yyyymmdd') �޿�������
     , b.salary �����ϴ�ñ޿�
     , b.salary - lag(b.salary) over (partition by b.emp_no order by b.from_date) �޿��λ��
     , round(avg(b.salary) over (partition by b.emp_no order by b.from_date)) �޿��������    
from employees a, salaries b
where a.emp_no = b.emp_no ;

/* �ǽ� 12. ��/�� ��ȯ(pivoting) */
/* 12-1. ���޺� ����� ���� (��->��) ��ȯ */
/* 12-1-1) ���޺� ����� ������ ���� view ���� */
create or replace view v_title_emp_rows
as
select title
     , count(*) cnt_emp
from titles
where to_date = '99991231'  -- ���� ����
group by title ;

select * from v_title_emp_rows ;

/* 12-1-2) ���޿� ���� (��->��) ��ȯ */
select '�����' �׸��
     , min(decode(title, 'Manager', cnt_emp)) Manager
     , min(decode(title, 'Technique Leader', cnt_emp)) Technique_Leader
     , min(decode(title, 'Senior Engineer', cnt_emp)) Senior_Engineer
     , min(decode(title, 'Engineer', cnt_emp)) Engineer
     , min(decode(title, 'Assistant Engineer', cnt_emp)) Assistant_Engineer
     , min(decode(title, 'Senior Staff', cnt_emp)) Senior_Staff
     , min(decode(title, 'Staff', cnt_emp)) Staff
from v_title_emp_rows ;

/* 12-2. ���޺� ����� ���� (��->��) ��ȯ */
/* 12-2-1) ���޺� ����� ������ ���� view ���� (12-1-1�� SQL�� view�� ����) */
create or replace view v_title_emp_columns
as
select '�����' �׸��
     , min(decode(title, 'Manager', cnt_emp)) Manager
     , min(decode(title, 'Technique Leader', cnt_emp)) Technique_Leader
     , min(decode(title, 'Senior Engineer', cnt_emp)) Senior_Engineer
     , min(decode(title, 'Engineer', cnt_emp)) Engineer
     , min(decode(title, 'Assistant Engineer', cnt_emp)) Assistant_Engineer
     , min(decode(title, 'Senior Staff', cnt_emp)) Senior_Staff
     , min(decode(title, 'Staff', cnt_emp)) Staff
from v_title_emp_rows ;

select * from v_title_emp_columns ;

/* 12-2-2) ���޿� ���� (��->��) ��ȯ */
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

/* 12-2-3) With�� �̿��ϱ� (12-2-1���� 12-2-2���� ���ļ� ǥ��) */
with title_emp_columns as
(select '�����' �׸��
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

/* 12-3. 10-3�� ���� ���� (��->��) ��ȯ */
/* 12-3-1) �μ���/���޺� �޿��տ� ���� view ���� (10-3�� SQL�� view�� ����) */
create or replace view v_dept_title_salaries
as
select nvl(y.dept_name, '�հ�') �μ���
     , x.title ���޸�
     , x.sum_sal �޿���
from ( select decode(grouping(b.dept_no), 1, '�հ�', b.dept_no) dept_no
            , decode(grouping(c.title), 1, '�հ�', c.title) title
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b, titles c
       where a.emp_no = b.emp_no
         and b.emp_no = c.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231' and c.to_date = '99991231'
       group by cube(b.dept_no, c.title) ) x, departments y
where x.dept_no = y.dept_no(+) ;

select * from v_dept_title_salaries ;

/* 12-3-2) ���޿� ���� (��->��) ��ȯ */
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ �μ���
     , min(decode(���޸�, 'Assistant Engineer', �޿���)) "Assitant Engineer"
     , min(decode(���޸�, 'Engineer', �޿���)) "Engineer"
     , min(decode(���޸�, 'Senior Engineer', �޿���)) "Senior Engineer"
     , min(decode(���޸�, 'Staff', �޿���)) "Staff"
     , min(decode(���޸�, 'Senior Staff', �޿���)) "Senior Staff"
     , min(decode(���޸�, 'Technique Leader', �޿���)) "Technique Leader"
     , min(decode(���޸�, 'Manager', �޿���)) "Manager"
     , min(decode(���޸�, '�հ�', �޿���)) "�հ�"
from v_dept_title_salaries
group by �μ��� ;

/* 12-2-3) With�� �̿��ϱ� (12-3-1���� 12-3-2���� ���ļ� ǥ��) */
with v_dept_title_salaries as
(select nvl(y.dept_name, '�հ�') �μ���
     , x.title ���޸�
     , x.sum_sal �޿���
from ( select decode(grouping(b.dept_no), 1, '�հ�', b.dept_no) dept_no
            , decode(grouping(c.title), 1, '�հ�', c.title) title
            , sum(a.salary) sum_sal
       from salaries a, dept_emp b, titles c
       where a.emp_no = b.emp_no
         and b.emp_no = c.emp_no
         and a.to_date = '99991231' and b.to_date = '99991231' and c.to_date = '99991231'
       group by cube(b.dept_no, c.title) ) x, departments y
where x.dept_no = y.dept_no(+))
select /*+ opt_param('_GBY_HASH_AGGREGATION_ENABLED' 'false') */ �μ���
     , min(decode(���޸�, 'Assistant Engineer', �޿���)) "Assitant Engineer"
     , min(decode(���޸�, 'Engineer', �޿���)) "Engineer"
     , min(decode(���޸�, 'Senior Engineer', �޿���)) "Senior Engineer"
     , min(decode(���޸�, 'Staff', �޿���)) "Staff"
     , min(decode(���޸�, 'Senior Staff', �޿���)) "Senior Staff"
     , min(decode(���޸�, 'Technique Leader', �޿���)) "Technique Leader"
     , min(decode(���޸�, 'Manager', �޿���)) "Manager"
     , min(decode(���޸�, '�հ�', �޿���)) "�հ�"
from v_dept_title_salaries
group by �μ��� ;









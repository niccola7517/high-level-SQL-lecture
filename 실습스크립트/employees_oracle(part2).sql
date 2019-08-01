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
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
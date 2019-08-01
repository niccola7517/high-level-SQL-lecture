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
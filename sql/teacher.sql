select
teacher_id,
source,
subject,
county_id,
complete_novice_task,
fst_hwk_type,
cross_subject,
is_be_invited,
fst_month,
case when min is null then 0 else 1 end as status,
case when min is null then max else min end as s_time
from
(select
teacher_id,
source,
subject,
county_id,
complete_novice_task,
fst_hwk_type,
cross_subject,
is_be_invited,
fst_month,
min (case when active_month is null then tem_number end),
max(tem_number) 
from
(select
ot.teacher_id,
oh.fst_month,
ot.source,
ot.subject,
ot.county_id,
ts.complete_novice_task,
ts.fst_hwk_type,
ts.cross_subject,
ts.is_be_invited,
otb.month as tem,
ohb.active_month,
row_number() over(partition by ot.teacher_id order by otb.month) -1 as tem_number
from
-- 教师注册表
(select
teacher_id,
case when source = 'androidRCTeacher' then 'Android'
     when source = 'iPhoneRCTeacher' then 'iOS'
     else 'Else' end as source,
case when subject = 0 then 'Math'
     when subject = 1 then 'Chi'
     when subject = 2 then 'Eng'
     else 'Sci' end as subject,
county_id
from view_o_teacher
where student_count >= 20) ot


join
-- 获取特征数据
(select
teacher_id,
complete_novice_task,
case when first_assgin_hwk_type_code in ('All', 'Review', 'OnlineMatch', 'Ocr', 'Listen&Write', 'ReadingExam', 'PersonalReading') then 'Daily' else 'Match' end as fst_hwk_type,
cross_subject,
is_be_invited
from o_teacher_stat) ts
on ts.teacher_id = ot.teacher_id

join
-- 获取教师的出生日期
(select
teacher_id,
min(month) as fst_month
from o_homework
-- -- 限制首次活跃时间不为2019年9月
where month < '2019-09-01'
group by teacher_id) oh

on ot.teacher_id = oh.teacher_id


join
-- 中转日期
(select
month
from view_o_teacher
-- 不含假期
where month not in ('2015-02-01', '2015-07-01', '2015-08-01',
		    '2016-02-01', '2016-07-01', '2016-08-01',
		    '2017-02-01', '2017-07-01', '2017-08-01',
		    '2018-02-01', '2018-07-01', '2018-08-01',
		    '2019-02-01', '2019-07-01', '2019-08-01')
group by 1) otb

on 1 = 1 


left join
-- 获取教师活动数据
(select
teacher_id,
month as active_month
from o_homework
group by 1, 2) ohb

on ot.teacher_id = ohb.teacher_id
and ohb.active_month = otb.month

where oh.fst_month <= otb.month
-- 剔除假期注册的老师
and oh.fst_month not in ('2015-02-01', '2015-07-01', '2015-08-01',
		         '2016-02-01', '2016-07-01', '2016-08-01',
		         '2017-02-01', '2017-07-01', '2017-08-01',
		         '2018-02-01', '2018-07-01', '2018-08-01',
		         '2019-02-01', '2019-07-01', '2019-08-01')
) aa

group by 1, 2, 3, 4, 5, 6, 7, 8, 9) aa

order by 1

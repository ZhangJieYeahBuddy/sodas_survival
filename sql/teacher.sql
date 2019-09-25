select eee.teacher_id,
       ot.source, ot.subject, ot.county_id,
       ts.fst_hwk_type, ts.complete_novice_task, ts.is_be_invited, ts.cross_subject,
       eee.fst_day, eee.days, eee.status
from
    (select *,
           max(case when flag = 1 then rn2 end) over (partition by teacher_id) flag4,
           min(case when flag3 = 1 then rn2 end) over (partition by teacher_id) flag5
    from
        (select *,
               case when max(flag3) over (partition by teacher_id) = 1 then 1 else 0 end as status--流失事件是否发生
        from
            (select *,
                   count(1) over (partition by teacher_id, flag, flag1) flag2,--连续作业或连续无作业天数
                   case when count(1) over (partition by teacher_id, flag, flag1) >= 90 and flag = 0 then 1 else 0 end as flag3--是否连续90天无作业
            from
                (select teacher_id, fst_day, day, hday, flag, day - fst_day days,
                       row_number() over (partition by teacher_id order by teacher_id, day) rn1,
                       row_number() over (partition by teacher_id, flag order by teacher_id, day) rn2,
                       row_number() over (partition by teacher_id order by teacher_id, day) - row_number() over (partition by teacher_id,flag order by teacher_id, day) flag1
                from
                    (select fst.teacher_id, fst.fst_day, m1.day, oh1.day hday,
                            case when oh1.day is null then 0 else 1 end flag--当天是否作业活跃
                    from
                        (select oh.teacher_id, min(oh.day) fst_day
                        from o_homework oh
                        join view_o_teacher ot on ot.teacher_id = oh.teacher_id and ot.student_count >= 20
                        group by 1)fst--首次作业活跃时间

                    join
                        (select day, month
                        from view_o_student
                        where month not in ('2015-02-01', '2015-07-01', '2015-08-01',
                                            '2016-02-01', '2016-07-01', '2016-08-01',
                                            '2017-02-01', '2017-07-01', '2017-08-01',
                                            '2018-02-01', '2018-07-01', '2018-08-01',
                                            '2019-02-01', '2019-07-01', '2019-08-01')
                        group by 1,2)m1 on m1.day >= fst.fst_day--拓展出每个人首次作业时间至今每一天

                    left join
                        (select teacher_id, day
                        from o_homework
                        group by 1,2)oh1 on fst.teacher_id = oh1.teacher_id and m1.day = oh1.day--每个人所有作业日期（去重）

                    where fst.fst_day between '2015-01-01' and '2019-09-01'
                    )aaa
                )bbb
            )ccc
        )ddd
    )eee

join
    (select teacher_id,
            case when source = 'androidRCTeacher' then 'Android'
                 when source = 'iPhoneRCTeacher' then 'iOS'
                 else 'Else' end as source,
            case when subject = 0 then 'Math'
                 when subject = 1 then 'Chi'
                 when subject = 2 then 'Eng'
                 else 'Sci' end as subject,
            county_id
    from view_o_teacher
    where student_count >= 20
    )ot on eee.teacher_id = ot.teacher_id-- 教师注册表

join
    (select teacher_id,
            complete_novice_task,
            case when first_assgin_hwk_type_code in ('All', 'Review', 'OnlineMatch', 'Ocr', 'Listen&Write', 'ReadingExam', 'PersonalReading') then 'Daily' else 'Match' end as fst_hwk_type,
            cross_subject,
            is_be_invited
    from o_teacher_stat
    ) ts on ts.teacher_id = ot.teacher_id-- 获取特征数据

where (eee.status = 0 and eee.flag4 = eee.rn2 and eee.flag = 1) --事件未发生的人对应最后一条作业活跃数据
   or (eee.status = 1 and eee.flag5 = eee.rn2 and eee.flag = 0); --事件发生的人对应第一条作业未活跃数据
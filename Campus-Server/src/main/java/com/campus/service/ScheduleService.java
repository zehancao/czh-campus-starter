package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.dto.ScheduleVO;
import com.campus.entity.ClassTimetable;
import com.campus.entity.PersonalTimetable;
import com.campus.entity.User;
import com.campus.mapper.ClassTimetableMapper;
import com.campus.mapper.PersonalTimetableMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ScheduleService {

    @Autowired
    private ClassTimetableMapper classTimetableMapper;

    @Autowired
    private PersonalTimetableMapper personalTimetableMapper;

    @Autowired
    private UserMapper userMapper;

    public List<ScheduleVO> getMySchedule(Long userId, Long semesterId) {
        if (semesterId == null) {
            semesterId = 1L;
        }
        List<ScheduleVO> result = new ArrayList<>();

        // 1. 班级课
        User user = userMapper.selectById(userId);
        if (user != null && user.getClassId() != null) {
            List<ClassTimetable> classList = classTimetableMapper.selectList(
                    new LambdaQueryWrapper<ClassTimetable>()
                            .eq(ClassTimetable::getClassId, user.getClassId())
                            .eq(ClassTimetable::getSemesterId, semesterId)
                            .orderByAsc(ClassTimetable::getDayOfWeek, ClassTimetable::getStartSection));
            for (ClassTimetable ct : classList) {
                ScheduleVO vo = new ScheduleVO();
                vo.setId(ct.getId());
                vo.setCourseName(ct.getCourseName());
                vo.setClassroom(ct.getClassroom());
                vo.setDayOfWeek(ct.getDayOfWeek());
                vo.setStartSection(ct.getStartSection());
                vo.setEndSection(ct.getEndSection());
                vo.setStartWeek(ct.getStartWeek());
                vo.setEndWeek(ct.getEndWeek());
                vo.setTeacherName(ct.getTeacher());
                vo.setSource("class");
                result.add(vo);
            }
        }

        // 2. 个人课
        List<PersonalTimetable> personalList = personalTimetableMapper.selectList(
                new LambdaQueryWrapper<PersonalTimetable>()
                        .eq(PersonalTimetable::getUserId, userId)
                        .eq(PersonalTimetable::getSemesterId, semesterId)
                        .orderByAsc(PersonalTimetable::getDayOfWeek, PersonalTimetable::getStartSection));
        for (PersonalTimetable pt : personalList) {
            ScheduleVO vo = new ScheduleVO();
            vo.setId(pt.getId());
            vo.setCourseName(pt.getCourseName());
            vo.setClassroom(pt.getClassroom());
            vo.setDayOfWeek(pt.getDayOfWeek());
            vo.setStartSection(pt.getStartSection());
            vo.setEndSection(pt.getEndSection());
            vo.setStartWeek(pt.getStartWeek());
            vo.setEndWeek(pt.getEndWeek());
            vo.setTeacherName(pt.getTeacher());
            vo.setSource("personal");
            result.add(vo);
        }

        return result;
    }

    public void addPersonalCourse(Long userId, Long semesterId, PersonalTimetable pt) {
        pt.setUserId(userId);
        pt.setSemesterId(semesterId);
        if (pt.getColor() == null || pt.getColor().isEmpty()) {
            pt.setColor("#E74C3C");
        }
        personalTimetableMapper.insert(pt);
    }

    public boolean deletePersonalCourse(Long userId, Long courseId) {
        PersonalTimetable pt = personalTimetableMapper.selectById(courseId);
        if (pt != null && pt.getUserId().equals(userId)) {
            personalTimetableMapper.deleteById(courseId);
            return true;
        }
        return false;
    }
}

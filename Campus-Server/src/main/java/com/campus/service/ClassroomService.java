package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.campus.dto.EmptyRoomVO;
import com.campus.entity.ClassTimetable;
import com.campus.entity.Classroom;
import com.campus.entity.Semester;
import com.campus.mapper.ClassTimetableMapper;
import com.campus.mapper.ClassroomMapper;
import com.campus.mapper.SemesterMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ClassroomService {

    @Autowired
    private ClassroomMapper classroomMapper;

    @Autowired
    private ClassTimetableMapper timetableMapper;

    @Autowired
    private SemesterMapper semesterMapper;

    private Long getCurrentSemesterId() {
        List<Semester> list = semesterMapper.selectList(
                new QueryWrapper<Semester>().eq("is_current", 1).last("LIMIT 1"));
        if (!list.isEmpty()) {
            return list.get(0).getId();
        }
        list = semesterMapper.selectList(
                new QueryWrapper<Semester>().orderByDesc("start_date").last("LIMIT 1"));
        if (!list.isEmpty()) {
            return list.get(0).getId();
        }
        return null;
    }

    public List<String> getBuildings() {
        QueryWrapper<Classroom> wrapper = new QueryWrapper<>();
        wrapper.select("DISTINCT building");
        List<Classroom> list = classroomMapper.selectList(wrapper);
        return list.stream().map(Classroom::getBuilding).collect(Collectors.toList());
    }

    public List<EmptyRoomVO> getEmptyRooms(String building, Integer dayOfWeek, Integer section, Integer week) {
        QueryWrapper<Classroom> roomWrapper = new QueryWrapper<>();
        if (building != null && !building.isEmpty()) {
            roomWrapper.eq("building", building);
        }
        roomWrapper.orderByAsc("building", "room_no");
        List<Classroom> allRooms = classroomMapper.selectList(roomWrapper);

        QueryWrapper<ClassTimetable> ttWrapper = new QueryWrapper<>();
        Long currentSemesterId = getCurrentSemesterId();
        if (currentSemesterId != null) {
            ttWrapper.eq("semester_id", currentSemesterId);
        }
        ttWrapper.eq("day_of_week", dayOfWeek);
        ttWrapper.le("start_section", section);
        ttWrapper.ge("end_section", section);
        if (week != null) {
            ttWrapper.le("start_week", week);
            ttWrapper.ge("end_week", week);
        }
        ttWrapper.isNotNull("classroom");
        ttWrapper.ne("classroom", "");
        List<ClassTimetable> occupied = timetableMapper.selectList(ttWrapper);

        List<String> occupiedRooms = occupied.stream()
                .map(ClassTimetable::getClassroom)
                .distinct()
                .collect(Collectors.toList());

        List<EmptyRoomVO> result = new ArrayList<>();
        for (Classroom room : allRooms) {
            if (!occupiedRooms.contains(room.getRoomNo())) {
                result.add(new EmptyRoomVO(
                        room.getId(),
                        room.getBuilding(),
                        room.getRoomNo(),
                        room.getCapacity(),
                        room.getHasProjector(),
                        room.getHasAc(),
                        room.getType()
                ));
            }
        }
        return result;
    }

    public List<ClassTimetable> getRoomSchedule(String classroom, Integer dayOfWeek) {
        QueryWrapper<ClassTimetable> wrapper = new QueryWrapper<>();
        Long currentSemesterId = getCurrentSemesterId();
        if (currentSemesterId != null) {
            wrapper.eq("semester_id", currentSemesterId);
        }
        wrapper.eq("classroom", classroom);
        if (dayOfWeek != null) {
            wrapper.eq("day_of_week", dayOfWeek);
        }
        wrapper.orderByAsc("start_section");
        return timetableMapper.selectList(wrapper);
    }
}

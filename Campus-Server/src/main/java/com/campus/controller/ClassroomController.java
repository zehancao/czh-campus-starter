package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.EmptyRoomVO;
import com.campus.entity.ClassTimetable;
import com.campus.service.ClassroomService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/classroom")
public class ClassroomController {

    @Autowired
    private ClassroomService classroomService;

    @GetMapping("/buildings")
    public Result<List<String>> getBuildings() {
        return Result.ok(classroomService.getBuildings());
    }

    @GetMapping("/rooms")
    public Result<List<String>> getRoomsByBuilding(@RequestParam String building) {
        return Result.ok(classroomService.getRoomsByBuilding(building));
    }

    @GetMapping("/empty")
    public Result<List<EmptyRoomVO>> getEmptyRooms(
            @RequestParam(required = false) String building,
            @RequestParam Integer dayOfWeek,
            @RequestParam Integer section,
            @RequestParam(required = false) Integer week) {
        return Result.ok(classroomService.getEmptyRooms(building, dayOfWeek, section, week));
    }

    @GetMapping("/schedule")
    public Result<List<ClassTimetable>> getRoomSchedule(
            @RequestParam String classroom,
            @RequestParam(required = false) Integer dayOfWeek) {
        return Result.ok(classroomService.getRoomSchedule(classroom, dayOfWeek));
    }
}

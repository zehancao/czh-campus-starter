package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.ScheduleVO;
import com.campus.dto.SemesterVO;
import com.campus.entity.PersonalTimetable;
import com.campus.service.AdminService;
import com.campus.service.ScheduleService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/schedule")
public class ScheduleController {

    @Autowired
    private ScheduleService scheduleService;

    @Autowired
    private AdminService adminService;

    @GetMapping("/my")
    public Result<List<ScheduleVO>> getMySchedule(HttpServletRequest request,
                                                   @RequestParam(required = false) Long semesterId) {
        Long userId = (Long) request.getAttribute("userId");
        List<ScheduleVO> list = scheduleService.getMySchedule(userId, semesterId);
        return Result.ok(list);
    }

    @GetMapping("/current-semester")
    public Result<SemesterVO> getCurrentSemester() {
        List<SemesterVO> list = adminService.getSemesters();
        for (SemesterVO vo : list) {
            if (vo.getIsCurrent() != null && vo.getIsCurrent() == 1) {
                return Result.ok(vo);
            }
        }
        if (!list.isEmpty()) {
            return Result.ok(list.get(0));
        }
        return Result.ok(null);
    }

    @PostMapping("/add-personal")
    public Result<?> addPersonalCourse(HttpServletRequest request, @RequestBody Map<String, Object> params) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return Result.error("未登录");
        }
        Long semesterId = params.get("semesterId") != null ? Long.valueOf(params.get("semesterId").toString()) : 1L;

        PersonalTimetable pt = new PersonalTimetable();
        pt.setCourseName(params.get("courseName") != null ? params.get("courseName").toString() : "");
        pt.setClassroom(params.get("classroom") != null ? params.get("classroom").toString() : "");
        pt.setTeacher(params.get("teacher") != null ? params.get("teacher").toString() : "");
        pt.setDayOfWeek(params.get("dayOfWeek") != null ? Integer.valueOf(params.get("dayOfWeek").toString()) : 1);
        pt.setStartSection(params.get("startSection") != null ? Integer.valueOf(params.get("startSection").toString()) : 1);
        pt.setEndSection(params.get("endSection") != null ? Integer.valueOf(params.get("endSection").toString()) : 2);
        pt.setStartWeek(params.get("startWeek") != null ? Integer.valueOf(params.get("startWeek").toString()) : 1);
        pt.setEndWeek(params.get("endWeek") != null ? Integer.valueOf(params.get("endWeek").toString()) : 16);
        pt.setColor(params.get("color") != null ? params.get("color").toString() : "#E74C3C");
        pt.setRemark(params.get("remark") != null ? params.get("remark").toString() : "个人加课");

        if (pt.getCourseName() == null || pt.getCourseName().trim().isEmpty()) {
            return Result.error("请输入课程名称");
        }

        scheduleService.addPersonalCourse(userId, semesterId, pt);
        return Result.ok();
    }

    @PostMapping("/delete-personal")
    public Result<?> deletePersonalCourse(HttpServletRequest request, @RequestBody Map<String, Object> params) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return Result.error("未登录");
        }
        Long courseId = params.get("id") != null ? Long.valueOf(params.get("id").toString()) : 0L;
        if (courseId <= 0) {
            return Result.error("参数错误");
        }
        boolean ok = scheduleService.deletePersonalCourse(userId, courseId);
        if (ok) {
            return Result.ok();
        }
        return Result.error("删除失败，课程不存在或无权限");
    }
}

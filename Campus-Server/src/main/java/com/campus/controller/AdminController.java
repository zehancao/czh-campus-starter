package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.AnnouncementRequest;
import com.campus.dto.BatchClassRequest;
import com.campus.dto.ClassVO;
import com.campus.dto.ProductVO;
import com.campus.dto.SemesterVO;
import com.campus.dto.TimetableVO;
import com.campus.entity.Announcement;
import com.campus.entity.LostFound;
import com.campus.entity.Product;
import com.campus.entity.User;
import com.campus.service.AdminService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @GetMapping("/semester/list")
    public Result<List<SemesterVO>> getSemesters() {
        List<SemesterVO> list = adminService.getSemesters();
        return Result.ok(list);
    }

    @PostMapping("/semester/add")
    public Result<Void> addSemester(@RequestBody SemesterVO vo) {
        adminService.addSemester(vo);
        return Result.ok();
    }

    @PutMapping("/semester/{id}")
    public Result<Void> updateSemester(@PathVariable Long id, @RequestBody SemesterVO vo) {
        adminService.updateSemester(id, vo);
        return Result.ok();
    }

    @PutMapping("/semester/{id}/set-current")
    public Result<Void> setCurrentSemester(@PathVariable Long id) {
        adminService.setCurrentSemester(id);
        return Result.ok();
    }

    @DeleteMapping("/semester/{id}")
    public Result<Void> deleteSemester(@PathVariable Long id) {
        adminService.deleteSemester(id);
        return Result.ok();
    }

    @GetMapping("/class/list")
    public Result<List<ClassVO>> getClasses(@RequestParam(required = false) String grade,
                                             @RequestParam(required = false) Long collegeId,
                                             @RequestParam(required = false) Long majorId) {
        List<ClassVO> list = adminService.getClasses(grade, collegeId, majorId);
        return Result.ok(list);
    }

    @GetMapping("/college/list")
    public Result<List<com.campus.entity.College>> getColleges() {
        return Result.ok(adminService.getColleges());
    }

    @GetMapping("/major/list")
    public Result<List<com.campus.entity.Major>> getMajors(@RequestParam(required = false) Long collegeId) {
        return Result.ok(adminService.getMajors(collegeId));
    }

    @GetMapping("/class/grades")
    public Result<List<String>> getGrades() {
        return Result.ok(adminService.getGrades());
    }

    @PostMapping("/class/add")
    public Result<Void> addClass(@RequestBody ClassVO vo) {
        adminService.addClass(vo);
        return Result.ok();
    }

    @PostMapping("/class/batch-add")
    public Result<Integer> batchAddClass(@RequestBody BatchClassRequest req) {
        int count = adminService.batchAddClass(req);
        return Result.ok(count);
    }

    @DeleteMapping("/class/by-grade")
    public Result<Integer> deleteClassByGrade(@RequestParam String grade) {
        int count = adminService.deleteClassByGrade(grade);
        return Result.ok(count);
    }

    @DeleteMapping("/class/{id}")
    public Result<Void> deleteClass(@PathVariable Long id) {
        adminService.deleteClass(id);
        return Result.ok();
    }

    @GetMapping("/timetable/class")
    public Result<List<TimetableVO>> getTimetableByClass(@RequestParam Long classId,
                                                          @RequestParam Long semesterId) {
        List<TimetableVO> list = adminService.getTimetableByClass(classId, semesterId);
        return Result.ok(list);
    }

    @PostMapping("/timetable/import")
    public Result<List<TimetableVO>> importSchedule(@RequestParam("file") MultipartFile file,
                                                     @RequestParam Long classId,
                                                     @RequestParam Long semesterId) throws Exception {
        List<TimetableVO> list = adminService.importSchedule(file, classId, semesterId);
        return Result.ok(list);
    }

    @GetMapping("/announcement/list")
    public Result<List<Announcement>> getAnnouncementList() {
        List<Announcement> list = adminService.getAnnouncementList();
        return Result.ok(list);
    }

    @PostMapping("/announcement/publish")
    public Result<Void> publishAnnouncement(HttpServletRequest request,
                                             @Valid @RequestBody AnnouncementRequest req) {
        Long userId = (Long) request.getAttribute("userId");
        adminService.publishAnnouncement(req, userId);
        return Result.ok();
    }

    @PutMapping("/announcement/{id}")
    public Result<Void> updateAnnouncement(@PathVariable Long id,
                                            @Valid @RequestBody AnnouncementRequest req) {
        adminService.updateAnnouncement(id, req);
        return Result.ok();
    }

    @DeleteMapping("/announcement/{id}")
    public Result<Void> deleteAnnouncement(@PathVariable Long id) {
        adminService.deleteAnnouncement(id);
        return Result.ok();
    }

    @GetMapping("/product/pending")
    public Result<List<ProductVO>> getPendingProducts() {
        return Result.ok(adminService.getPendingProducts());
    }

    @PostMapping("/product/approve")
    public Result<Void> approveProduct(@RequestParam Long productId) {
        adminService.approveProduct(productId);
        return Result.ok();
    }

    @PostMapping("/product/reject")
    public Result<Void> rejectProduct(@RequestParam Long productId) {
        adminService.rejectProduct(productId);
        return Result.ok();
    }

    @GetMapping("/user/list")
    public Result<List<User>> getUserList() {
        return Result.ok(adminService.getAllUsers());
    }

    @GetMapping("/lost-found/list")
    public Result<List<LostFound>> getLostFoundList() {
        return Result.ok(adminService.getAllLostFound());
    }

    @GetMapping("/product/list")
    public Result<List<Product>> getProductList() {
        return Result.ok(adminService.getAllProducts());
    }
}

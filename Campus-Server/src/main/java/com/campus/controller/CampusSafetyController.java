package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.SafetyContactVO;
import com.campus.dto.SafetyReportVO;
import com.campus.entity.SafetyReport;
import com.campus.service.CampusSafetyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/safety")
public class CampusSafetyController {

    @Autowired
    private CampusSafetyService campusSafetyService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @PostMapping("/report")
    public Result<SafetyReport> submitReport(@RequestAttribute("userId") Long userId,
                                              @RequestBody SafetyReport report) {
        return Result.ok(campusSafetyService.submitReport(userId, report));
    }

    @GetMapping("/list")
    public Result<List<SafetyReportVO>> getList(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.ok(campusSafetyService.getList(status, page, size));
    }

    @GetMapping("/detail")
    public Result<SafetyReportVO> getDetail(@RequestParam Long id) {
        SafetyReportVO vo = campusSafetyService.getDetail(id);
        if (vo == null) return Result.error(404, "求助记录不存在");
        return Result.ok(vo);
    }

    @PostMapping("/handle")
    public Result<Boolean> handleReport(@RequestAttribute("userId") Long userId,
                                         @RequestParam Long id,
                                         @RequestParam Integer status,
                                         @RequestParam(required = false) String remark) {
        boolean ok = campusSafetyService.handleReport(userId, id, status, remark);
        if (!ok) return Result.error(400, "处理失败");
        return Result.ok(true);
    }

    @GetMapping("/my-reports")
    public Result<List<SafetyReportVO>> myReports(@RequestAttribute("userId") Long userId) {
        return Result.ok(campusSafetyService.getMyReports(userId));
    }

    @GetMapping("/contacts")
    public Result<List<SafetyContactVO>> getContacts() {
        return Result.ok(campusSafetyService.getContacts());
    }

    @PostMapping("/upload")
    public Result<String> uploadImage(@RequestAttribute("userId") Long userId,
                                       @RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        Set<String> ALLOWED = Set.of("jpg", "jpeg", "png", "gif", "webp");
        if (!ALLOWED.contains(ext.toLowerCase().replace(".", ""))) {
            return Result.error("不支持的文件类型");
        }
        String filename = UUID.randomUUID().toString().replace("-", "") + ext;
        File dir = new File(uploadDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        try {
            file.transferTo(new File(dir, filename));
        } catch (IOException e) {
            return Result.error("上传失败");
        }
        String url = "/uploads/" + filename;
        return Result.ok(url);
    }
}

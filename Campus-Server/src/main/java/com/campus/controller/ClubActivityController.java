package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.ClubActivityVO;
import com.campus.entity.ClubActivity;
import com.campus.service.ClubActivityService;
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
@RequestMapping("/api/club-activity")
public class ClubActivityController {

    @Autowired
    private ClubActivityService clubActivityService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/list")
    public Result<List<ClubActivityVO>> getList(
            @RequestParam(required = false) String club,
            @RequestParam(required = false) Integer status,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return Result.ok(clubActivityService.getList(club, status, userId));
    }

    @GetMapping("/detail")
    public Result<ClubActivityVO> getDetail(@RequestParam Long id,
                                             @RequestAttribute(value = "userId", required = false) Long userId) {
        ClubActivityVO vo = clubActivityService.getDetail(id, userId);
        if (vo == null) return Result.error(404, "活动不存在");
        return Result.ok(vo);
    }

    @PostMapping("/publish")
    public Result<ClubActivity> publish(@RequestAttribute("userId") Long userId,
                                         @RequestBody ClubActivity activity) {
        return Result.ok(clubActivityService.publish(userId, activity));
    }

    @PostMapping("/upload-cover")
    public Result<String> uploadCover(@RequestAttribute("userId") Long userId,
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

    @PostMapping("/register")
    public Result<Boolean> register(@RequestAttribute("userId") Long userId,
                                     @RequestParam Long activityId) {
        boolean ok = clubActivityService.register(userId, activityId);
        if (!ok) return Result.error(400, "报名失败（已满/已报名/活动已结束）");
        return Result.ok(true);
    }

    @PostMapping("/cancel")
    public Result<Boolean> cancel(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long activityId) {
        boolean ok = clubActivityService.cancelRegistration(userId, activityId);
        if (!ok) return Result.error(400, "取消失败");
        return Result.ok(true);
    }

    @GetMapping("/my-activities")
    public Result<List<ClubActivityVO>> myActivities(@RequestAttribute("userId") Long userId) {
        return Result.ok(clubActivityService.getMyActivities(userId));
    }
}

package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.StudyShareVO;
import com.campus.entity.StudyShare;
import com.campus.service.StudyShareService;
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
@RequestMapping("/api/study-share")
public class StudyShareController {

    @Autowired
    private StudyShareService studyShareService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/list")
    public Result<List<StudyShareVO>> getList(
            @RequestParam(required = false) String courseName,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return Result.ok(studyShareService.getList(courseName, category, page, size, userId));
    }

    @GetMapping("/detail")
    public Result<StudyShareVO> getDetail(@RequestParam Long id,
                                           @RequestAttribute(value = "userId", required = false) Long userId) {
        StudyShareVO vo = studyShareService.getDetail(id, userId);
        if (vo == null) return Result.error(404, "资料不存在");
        return Result.ok(vo);
    }

    @PostMapping("/publish")
    public Result<StudyShare> publish(@RequestAttribute("userId") Long userId,
                                       @RequestBody StudyShare share) {
        return Result.ok(studyShareService.publish(userId, share));
    }

    @PostMapping("/delete")
    public Result<Boolean> delete(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long shareId) {
        boolean ok = studyShareService.delete(userId, shareId);
        if (!ok) return Result.error(400, "删除失败（非作者或资料不存在）");
        return Result.ok(true);
    }

    @PostMapping("/like")
    public Result<Boolean> like(@RequestAttribute("userId") Long userId,
                                 @RequestParam Long shareId) {
        return Result.ok(studyShareService.like(userId, shareId));
    }

    @PostMapping("/favorite")
    public Result<Boolean> favorite(@RequestAttribute("userId") Long userId,
                                     @RequestParam Long shareId) {
        return Result.ok(studyShareService.favorite(userId, shareId));
    }

    @PostMapping("/download")
    public Result<Boolean> download(@RequestAttribute("userId") Long userId,
                                     @RequestParam Long shareId) {
        studyShareService.download(shareId);
        return Result.ok(true);
    }

    @PostMapping("/report")
    public Result<Boolean> report(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long shareId) {
        boolean ok = studyShareService.report(userId, shareId);
        if (!ok) return Result.error(400, "举报失败");
        return Result.ok(true);
    }

    @GetMapping("/my-shares")
    public Result<List<StudyShareVO>> myShares(@RequestAttribute("userId") Long userId) {
        return Result.ok(studyShareService.getMyShares(userId));
    }

    @GetMapping("/my-favorites")
    public Result<List<StudyShareVO>> myFavorites(@RequestAttribute("userId") Long userId) {
        return Result.ok(studyShareService.getMyFavorites(userId));
    }

    @PostMapping("/upload")
    public Result<String> upload(@RequestAttribute("userId") Long userId,
                                  @RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        Set<String> ALLOWED = Set.of("pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx",
                "jpg", "jpeg", "png", "gif", "webp", "zip", "rar");
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
}

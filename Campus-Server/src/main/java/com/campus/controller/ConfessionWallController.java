package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.ConfessionCommentVO;
import com.campus.dto.ConfessionPostVO;
import com.campus.entity.ConfessionComment;
import com.campus.entity.ConfessionPost;
import com.campus.service.ConfessionWallService;
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
@RequestMapping("/api/confession-wall")
public class ConfessionWallController {

    @Autowired
    private ConfessionWallService confessionWallService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/list")
    public Result<List<ConfessionPostVO>> getList(
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return Result.ok(confessionWallService.getList(category, page, size, userId));
    }

    @GetMapping("/detail")
    public Result<ConfessionPostVO> getDetail(@RequestParam Long id,
                                               @RequestAttribute(value = "userId", required = false) Long userId) {
        ConfessionPostVO vo = confessionWallService.getDetail(id, userId);
        if (vo == null) return Result.error(404, "帖子不存在");
        return Result.ok(vo);
    }

    @PostMapping("/publish")
    public Result<ConfessionPost> publish(@RequestAttribute("userId") Long userId,
                                           @RequestBody ConfessionPost post) {
        return Result.ok(confessionWallService.publish(userId, post));
    }

    @PostMapping("/delete")
    public Result<Boolean> delete(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long postId) {
        boolean ok = confessionWallService.delete(userId, postId);
        if (!ok) return Result.error(400, "删除失败（非作者或帖子不存在）");
        return Result.ok(true);
    }

    @PostMapping("/like")
    public Result<Boolean> like(@RequestAttribute("userId") Long userId,
                                 @RequestParam Long postId) {
        return Result.ok(confessionWallService.like(userId, postId));
    }

    @PostMapping("/comment")
    public Result<ConfessionComment> comment(@RequestAttribute("userId") Long userId,
                                              @RequestParam Long postId,
                                              @RequestParam String content,
                                              @RequestParam(defaultValue = "0") Integer isAnonymous) {
        return Result.ok(confessionWallService.comment(userId, postId, content, isAnonymous));
    }

    @PostMapping("/report")
    public Result<Boolean> report(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long postId) {
        boolean ok = confessionWallService.report(userId, postId);
        if (!ok) return Result.error(400, "举报失败");
        return Result.ok(true);
    }

    @GetMapping("/my-posts")
    public Result<List<ConfessionPostVO>> myPosts(@RequestAttribute("userId") Long userId) {
        return Result.ok(confessionWallService.getMyPosts(userId));
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

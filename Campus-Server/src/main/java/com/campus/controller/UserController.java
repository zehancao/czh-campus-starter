package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.LoginRequest;
import com.campus.dto.RegisterRequest;
import com.campus.dto.UserVO;
import com.campus.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@Valid @RequestBody LoginRequest req) {
        Map<String, Object> data = userService.login(req);
        return Result.ok(data);
    }

    @PostMapping("/register")
    public Result<Void> register(@Valid @RequestBody RegisterRequest req) {
        userService.register(req);
        return Result.ok();
    }

    @GetMapping("/profile")
    public Result<UserVO> getProfile(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        UserVO vo = userService.getProfile(userId);
        return Result.ok(vo);
    }

    @PostMapping("/change-password")
    public Result<Boolean> changePassword(HttpServletRequest request, @RequestBody Map<String, String> body) {
        Long userId = (Long) request.getAttribute("userId");
        String oldPwd = body.get("oldPassword");
        String newPwd = body.get("newPassword");
        if (oldPwd == null || oldPwd.isEmpty() || newPwd == null || newPwd.isEmpty()) {
            return Result.error(400, "请输入旧密码和新密码");
        }
        boolean ok = userService.changePassword(userId, oldPwd, newPwd);
        if (!ok) {
            return Result.error(400, "旧密码错误");
        }
        return Result.ok(true);
    }

    @PostMapping("/upload-avatar")
    public Result<String> uploadAvatar(HttpServletRequest request, @RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
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
        Long userId = (Long) request.getAttribute("userId");
        userService.updateAvatar(userId, url);
        return Result.ok(url);
    }

    @PostMapping("/update-name")
    public Result<Void> updateName(HttpServletRequest request, @RequestBody Map<String, String> body) {
        Long userId = (Long) request.getAttribute("userId");
        String name = body.get("name");
        if (name == null || name.trim().isEmpty()) {
            return Result.error(400, "用户名不能为空");
        }
        userService.updateName(userId, name.trim());
        return Result.ok();
    }

    @PostMapping("/update-avatar")
    public Result<Void> updateAvatar(HttpServletRequest request, @RequestBody Map<String, String> body) {
        Long userId = (Long) request.getAttribute("userId");
        String avatar = body.get("avatar");
        if (avatar == null || avatar.isEmpty()) {
            return Result.error(400, "头像不能为空");
        }
        userService.updateAvatar(userId, avatar);
        return Result.ok();
    }
}

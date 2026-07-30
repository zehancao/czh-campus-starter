package com.campus.controller;

import com.campus.common.Result;
import com.campus.service.FeedbackService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/feedback")
public class FeedbackController {

    @Autowired
    private FeedbackService feedbackService;

    @PostMapping("/submit")
    public Result submitFeedback(@RequestBody Map<String, String> params) {
        String userName = params.getOrDefault("userName", "匿名用户");
        String contact = params.getOrDefault("contact", "");
        String content = params.getOrDefault("content", "");
        if (content.isBlank()) {
            return Result.error("反馈内容不能为空");
        }
        try {
            feedbackService.sendFeedbackAsync(userName, contact, content);
            return Result.ok("反馈已发送，感谢您的意见！");
        } catch (Exception e) {
            return Result.error("发送失败，请稍后重试");
        }
    }
}

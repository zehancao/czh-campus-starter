package com.campus.controller;

import com.campus.service.ComplaintService;
import com.campus.common.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/complaint")
public class ComplaintController {

    @Autowired
    private ComplaintService complaintService;

    @PostMapping("/submit")
    public Result<?> submit(@RequestBody Map<String, Object> params, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return Result.error("未登录");
        }
        Long defendantId = Long.valueOf(params.get("defendantId").toString());
        Long productId = params.get("productId") != null ? Long.valueOf(params.get("productId").toString()) : null;
        String reason = params.get("reason").toString();
        if (reason == null || reason.trim().isEmpty()) {
            return Result.error("请填写投诉原因");
        }
        if (defendantId.equals(userId)) {
            return Result.error("不能投诉自己");
        }
        complaintService.submitComplaint(userId, defendantId, productId, reason.trim());
        return Result.ok();
    }

    @GetMapping("/my-complaints")
    public Result<?> myComplaints(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return Result.error("未登录");
        }
        List<Map<String, Object>> list = complaintService.getMyComplaints(userId);
        return Result.ok(list);
    }

    @GetMapping("/credit-score")
    public Result<?> creditScore(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return Result.error("未登录");
        }
        int score = complaintService.getCreditScore(userId);
        boolean canTrade = complaintService.canTrade(userId);
        Map<String, Object> data = Map.of("creditScore", score, "canTrade", canTrade);
        return Result.ok(data);
    }

    @GetMapping("/list")
    public Result<?> list() {
        List<Map<String, Object>> list = complaintService.getAllComplaints();
        return Result.ok(list);
    }

    @PostMapping("/process/{id}")
    public Result<?> process(@PathVariable Long id) {
        complaintService.processComplaint(id);
        return Result.ok();
    }

    @PostMapping("/reject/{id}")
    public Result<?> reject(@PathVariable Long id) {
        complaintService.rejectComplaint(id);
        return Result.ok();
    }

    @GetMapping("/{id}/chat-records")
    public Result<?> chatRecords(@PathVariable Long id) {
        Map<String, Object> records = complaintService.getComplaintChatRecords(id);
        return Result.ok(records);
    }
}

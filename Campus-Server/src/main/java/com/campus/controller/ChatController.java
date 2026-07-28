package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.ChatMessageVO;
import com.campus.dto.ConversationVO;
import com.campus.service.ChatService;
import com.campus.websocket.ChatWebSocketHandler;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private ChatWebSocketHandler webSocketHandler;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/conversations")
    public Result<List<ConversationVO>> getConversations(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        List<ConversationVO> list = chatService.getConversations(userId);
        return Result.ok(list);
    }

    @GetMapping("/messages/{conversationId}")
    public Result<List<ChatMessageVO>> getMessages(HttpServletRequest request,
                                                     @PathVariable("conversationId") Long conversationId) {
        Long userId = (Long) request.getAttribute("userId");
        List<ChatMessageVO> list = chatService.getMessages(conversationId, userId);
        return Result.ok(list);
    }

    @PostMapping("/send")
    public Result<ChatMessageVO> sendMessage(HttpServletRequest request,
                                              @RequestBody Map<String, Object> body) {
        Long userId = (Long) request.getAttribute("userId");
        Long conversationId = Long.valueOf(body.get("conversationId").toString());
        String content = body.get("content").toString();
        String msgType = body.getOrDefault("msgType", "text").toString();
        ChatMessageVO vo = chatService.sendMessage(userId, conversationId, content, msgType);
        Long receiverId = chatService.getReceiverId(conversationId, userId);
        webSocketHandler.pushChatMessage(vo, userId, receiverId);
        return Result.ok(vo);
    }

    @GetMapping("/unread-count")
    public Result<Map<String, Object>> getUnreadCount(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        int count = chatService.getUnreadCount(userId);
        return Result.ok(Map.of("unreadCount", count));
    }

    @PostMapping("/create-conversation")
    public Result<Map<String, Object>> createConversation(HttpServletRequest request,
                                                            @RequestBody Map<String, Object> body) {
        Long userId = (Long) request.getAttribute("userId");
        Long otherUserId = Long.valueOf(body.get("otherUserId").toString());
        Long productId = body.get("productId") != null ?
                Long.valueOf(body.get("productId").toString()) : null;
        Long conversationId = chatService.getOrCreateConversation(userId, otherUserId, productId);
        return Result.ok(Map.of("conversationId", conversationId));
    }

    @GetMapping("/online-users")
    public Result<?> getOnlineUsers() {
        return Result.ok(webSocketHandler.getOnlineUserIds());
    }

    @PostMapping("/upload-media")
    public Result<String> uploadMedia(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        Set<String> allowed = Set.of("jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "m4v", "avi");
        if (!allowed.contains(ext.toLowerCase().replace(".", ""))) {
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
        return Result.ok("/uploads/" + filename);
    }
}

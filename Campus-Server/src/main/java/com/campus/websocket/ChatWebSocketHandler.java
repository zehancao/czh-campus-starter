package com.campus.websocket;

import com.campus.dto.ChatMessageVO;
import com.campus.entity.ChatMessage;
import com.campus.service.ChatService;
import com.campus.common.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    @Autowired
    private ChatService chatService;

    @Autowired
    private JwtUtil jwtUtil;

    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private final ConcurrentHashMap<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, Long> lastPongTime = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = getUserId(session);
        if (userId == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        WebSocketSession oldSession = sessions.get(userId);
        if (oldSession != null && oldSession.isOpen()) {
            oldSession.close(CloseStatus.NORMAL);
        }
        sessions.put(userId, session);
        lastPongTime.put(userId, System.currentTimeMillis());

        broadcastUserStatus(userId, true);

        List<ChatMessage> unread = chatService.getUnreadMessages(userId);
        for (ChatMessage msg : unread) {
            ChatMessageVO vo = toVO(msg, userId);
            sendMessageToUser(userId, buildMessageJson("message", vo));
        }

        sendMessageToUser(userId, buildMessageJson("unread_update", Map.of("unreadCount", chatService.getUnreadCount(userId))));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        Long userId = getUserId(session);
        if (userId == null) return;

        try {
            Map<String, Object> payload = objectMapper.readValue(message.getPayload(), Map.class);
            String type = (String) payload.get("type");

            if ("pong".equals(type)) {
                lastPongTime.put(userId, System.currentTimeMillis());
                return;
            }

            if ("message".equals(type)) {
                Long conversationId = Long.valueOf(payload.get("conversationId").toString());
                String content = payload.get("content").toString();
                String msgType = payload.getOrDefault("msgType", "text").toString();

                ChatMessageVO vo = chatService.sendMessage(userId, conversationId, content, msgType);

                Long receiverId = chatService.getReceiverId(conversationId, userId);
                pushChatMessage(vo, userId, receiverId);
            }

            if ("mark_read".equals(type)) {
                Long conversationId = Long.valueOf(payload.get("conversationId").toString());
                chatService.markAsRead(conversationId, userId);
                sendMessageToUser(userId, buildMessageJson("unread_update",
                    Map.of("unreadCount", chatService.getUnreadCount(userId))));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = getUserId(session);
        if (userId != null) {
            sessions.remove(userId);
            lastPongTime.remove(userId);
            broadcastUserStatus(userId, false);
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        Long userId = getUserId(session);
        if (userId != null) {
            sessions.remove(userId);
            lastPongTime.remove(userId);
            broadcastUserStatus(userId, false);
        }
        if (session.isOpen()) {
            session.close(CloseStatus.SERVER_ERROR);
        }
    }

    public void sendMessageToUser(Long userId, String message) {
        if (userId == null) return;
        WebSocketSession session = sessions.get(userId);
        if (session != null && session.isOpen()) {
            try {
                session.sendMessage(new TextMessage(message));
            } catch (IOException e) {
                sessions.remove(userId);
            }
        }
    }

    public List<Long> getOnlineUserIds() {
        return new ArrayList<>(sessions.keySet());
    }

    public boolean isUserOnline(Long userId) {
        return sessions.containsKey(userId);
    }

    public void pushChatMessage(ChatMessageVO vo, Long senderId, Long receiverId) {
        String msgJson = buildMessageJson("message", vo);
        sendMessageToUser(senderId, msgJson);
        sendMessageToUser(receiverId, msgJson);
        if (receiverId != null) {
            sendMessageToUser(receiverId, buildMessageJson("unread_update",
                Map.of("unreadCount", chatService.getUnreadCount(receiverId))));
        }
        if (senderId != null) {
            sendMessageToUser(senderId, buildMessageJson("unread_update",
                Map.of("unreadCount", chatService.getUnreadCount(senderId))));
        }
    }

    private void broadcastUserStatus(Long userId, boolean online) {
        String json = buildMessageJson("user_status", Map.of("userId", userId, "online", online));
        for (Map.Entry<Long, WebSocketSession> entry : sessions.entrySet()) {
            if (!entry.getKey().equals(userId) && entry.getValue().isOpen()) {
                try {
                    entry.getValue().sendMessage(new TextMessage(json));
                } catch (IOException ignored) {}
            }
        }
    }

    public void sendPingToAll() {
        long now = System.currentTimeMillis();
        String pingJson = buildMessageJson("ping", Map.of());
        Iterator<Map.Entry<Long, WebSocketSession>> it = sessions.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<Long, WebSocketSession> entry = it.next();
            Long userId = entry.getKey();
            WebSocketSession session = entry.getValue();
            Long lastPong = lastPongTime.get(userId);
            if (lastPong != null && now - lastPong > 60000) {
                try { session.close(CloseStatus.GOING_AWAY); } catch (IOException ignored) {}
                it.remove();
                lastPongTime.remove(userId);
                broadcastUserStatus(userId, false);
                continue;
            }
            if (session.isOpen()) {
                try { session.sendMessage(new TextMessage(pingJson)); } catch (IOException e) { it.remove(); }
            }
        }
    }

    private Long getUserId(WebSocketSession session) {
        String query = session.getUri().getQuery();
        if (query == null) return null;
        for (String param : query.split("&")) {
            String[] kv = param.split("=");
            if (kv.length == 2 && "token".equals(kv[0])) {
                try {
                    if (jwtUtil.validateToken(kv[1])) {
                        return jwtUtil.getUserIdFromToken(kv[1]);
                    }
                } catch (Exception ignored) {}
            }
        }
        return null;
    }

    private ChatMessageVO toVO(ChatMessage msg, Long userId) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setId(msg.getId());
        vo.setConversationId(msg.getConversationId());
        vo.setSenderId(msg.getSenderId());
        vo.setContent(msg.getContent());
        vo.setMsgType(msg.getMsgType());
        vo.setCreateTime(msg.getCreateTime() != null ? msg.getCreateTime().format(FORMATTER) : "");
        vo.setIsMine(msg.getSenderId().equals(userId));
        return vo;
    }

    private String buildMessageJson(String type, Object data) {
        try {
            Map<String, Object> msg = new HashMap<>();
            msg.put("type", type);
            msg.put("data", data);
            return objectMapper.writeValueAsString(msg);
        } catch (Exception e) {
            return "{}";
        }
    }
}

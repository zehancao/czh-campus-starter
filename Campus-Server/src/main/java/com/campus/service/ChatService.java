package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.campus.dto.ChatMessageVO;
import com.campus.dto.ConversationVO;
import com.campus.entity.ChatConversation;
import com.campus.entity.ChatMessage;
import com.campus.mapper.ChatMessageMapper;
import com.campus.mapper.ConversationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
public class ChatService {

    @Autowired
    private ConversationMapper conversationMapper;

    @Autowired
    private ChatMessageMapper chatMessageMapper;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public List<ConversationVO> getConversations(Long userId) {
        List<ChatConversation> list = conversationMapper.selectByUserId(userId);
        List<ConversationVO> result = new ArrayList<>();
        for (ChatConversation cc : list) {
            ConversationVO vo = new ConversationVO();
            vo.setId(cc.getId());
            vo.setOtherUserId(cc.getUser1Id().equals(userId) ? cc.getUser2Id() : cc.getUser1Id());
            vo.setOtherUserName(cc.getOtherUserName());
            vo.setLastMessage(cc.getLastMessage());
            vo.setLastTime(cc.getLastTime() != null ? cc.getLastTime().format(FORMATTER) : "");
            vo.setUnreadCount(cc.getUnreadCount() != null ? cc.getUnreadCount() : 0);
            vo.setProductId(cc.getProductId());
            result.add(vo);
        }
        return result;
    }

    public List<ChatMessageVO> getMessages(Long conversationId, Long userId) {
        List<ChatMessage> list = chatMessageMapper.selectList(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getConversationId, conversationId)
                        .orderByAsc(ChatMessage::getCreateTime));
        chatMessageMapper.update(null,
                new LambdaUpdateWrapper<ChatMessage>()
                        .eq(ChatMessage::getConversationId, conversationId)
                        .ne(ChatMessage::getSenderId, userId)
                        .eq(ChatMessage::getIsRead, 0)
                        .set(ChatMessage::getIsRead, 1));
        List<ChatMessageVO> result = new ArrayList<>();
        for (ChatMessage msg : list) {
            result.add(toVO(msg, userId));
        }
        return result;
    }

    public ChatMessageVO sendMessage(Long senderId, Long conversationId, String content, String msgType) {
        ChatMessage msg = new ChatMessage();
        msg.setConversationId(conversationId);
        msg.setSenderId(senderId);
        msg.setContent(content);
        msg.setMsgType(msgType != null ? msgType : "text");
        msg.setIsRead(0);
        msg.setCreateTime(LocalDateTime.now());
        chatMessageMapper.insert(msg);

        ChatConversation cc = conversationMapper.selectById(conversationId);
        if (cc != null) {
            String lastMessage = buildLastMessage(content, msgType);
            cc.setLastMessage(lastMessage.length() > 50 ? lastMessage.substring(0, 50) : lastMessage);
            cc.setLastTime(LocalDateTime.now());
            conversationMapper.updateById(cc);
        }

        return toVO(msg, senderId);
    }

    private String buildLastMessage(String content, String msgType) {
        if ("image".equals(msgType)) {
            return "[图片]";
        }
        if ("product".equals(msgType)) {
            return "[商品卡片]";
        }
        if ("video".equals(msgType)) {
            return "[视频]";
        }
        return content != null ? content : "";
    }

    public Long getReceiverId(Long conversationId, Long senderId) {
        ChatConversation cc = conversationMapper.selectById(conversationId);
        if (cc == null) return null;
        return cc.getUser1Id().equals(senderId) ? cc.getUser2Id() : cc.getUser1Id();
    }

    public List<ChatMessage> getUnreadMessages(Long userId) {
        List<ChatConversation> conversations = conversationMapper.selectByUserId(userId);
        List<ChatMessage> unreadList = new ArrayList<>();
        for (ChatConversation cc : conversations) {
            List<ChatMessage> msgs = chatMessageMapper.selectList(
                new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getConversationId, cc.getId())
                    .ne(ChatMessage::getSenderId, userId)
                    .eq(ChatMessage::getIsRead, 0)
                    .orderByAsc(ChatMessage::getCreateTime));
            unreadList.addAll(msgs);
        }
        return unreadList;
    }

    public void markAsRead(Long conversationId, Long userId) {
        chatMessageMapper.update(null,
            new LambdaUpdateWrapper<ChatMessage>()
                .eq(ChatMessage::getConversationId, conversationId)
                .ne(ChatMessage::getSenderId, userId)
                .eq(ChatMessage::getIsRead, 0)
                .set(ChatMessage::getIsRead, 1));
    }

    public int getUnreadCount(Long userId) {
        List<ChatConversation> list = conversationMapper.selectByUserId(userId);
        int total = 0;
        for (ChatConversation cc : list) {
            if (cc.getUnreadCount() != null) {
                total += cc.getUnreadCount();
            }
        }
        return total;
    }

    public Long getOrCreateConversation(Long user1Id, Long user2Id, Long productId) {
        Long minUser = Math.min(user1Id, user2Id);
        Long maxUser = Math.max(user1Id, user2Id);
        LambdaQueryWrapper<ChatConversation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ChatConversation::getUser1Id, minUser)
                .eq(ChatConversation::getUser2Id, maxUser);
        ChatConversation existing = conversationMapper.selectOne(wrapper);
        if (existing != null) {
            return existing.getId();
        }
        ChatConversation cc = new ChatConversation();
        cc.setUser1Id(minUser);
        cc.setUser2Id(maxUser);
        cc.setProductId(productId);
        cc.setCreateTime(LocalDateTime.now());
        conversationMapper.insert(cc);
        return cc.getId();
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
}

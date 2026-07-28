package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.entity.Complaint;
import com.campus.entity.ChatConversation;
import com.campus.entity.ChatMessage;
import com.campus.entity.User;
import com.campus.mapper.ChatMessageMapper;
import com.campus.mapper.ComplaintMapper;
import com.campus.mapper.ConversationMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ComplaintService {

    @Autowired
    private ComplaintMapper complaintMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ConversationMapper conversationMapper;

    @Autowired
    private ChatMessageMapper chatMessageMapper;

    private static final DateTimeFormatter CHAT_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    @Transactional
    public void submitComplaint(Long complainantId, Long defendantId, Long productId, String reason) {
        // 防重复：同一人对同一被投诉人的同一商品已存在待审核投诉则不允许重复提交，避免刷投诉攻击
        LambdaQueryWrapper<Complaint> existWrapper = new LambdaQueryWrapper<>();
        existWrapper.eq(Complaint::getComplainantId, complainantId)
                    .eq(Complaint::getDefendantId, defendantId)
                    .eq(productId != null, Complaint::getProductId, productId)
                    .eq(Complaint::getStatus, 0);
        if (complaintMapper.selectCount(existWrapper) > 0) {
            throw new RuntimeException("已存在待审核的相同投诉，请等待管理员处理");
        }

        Complaint complaint = new Complaint();
        complaint.setComplainantId(complainantId);
        complaint.setDefendantId(defendantId);
        complaint.setProductId(productId);
        complaint.setReason(reason);
        complaint.setStatus(0);
        complaintMapper.insert(complaint);
    }

    public List<Map<String, Object>> getMyComplaints(Long userId) {
        LambdaQueryWrapper<Complaint> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Complaint::getComplainantId, userId)
               .or()
               .eq(Complaint::getDefendantId, userId)
               .orderByDesc(Complaint::getCreateTime);
        List<Complaint> complaints = complaintMapper.selectList(wrapper);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Complaint c : complaints) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("complainantId", c.getComplainantId());
            map.put("defendantId", c.getDefendantId());
            map.put("productId", c.getProductId());
            map.put("reason", c.getReason());
            map.put("status", c.getStatus());
            map.put("createTime", c.getCreateTime());
            User complainant = userMapper.selectById(c.getComplainantId());
            if (complainant != null) {
                map.put("complainantName", complainant.getName());
            }
            User defendant = userMapper.selectById(c.getDefendantId());
            if (defendant != null) {
                map.put("defendantName", defendant.getName());
            }
            result.add(map);
        }
        return result;
    }

    public List<Map<String, Object>> getAllComplaints() {
        List<Complaint> complaints = complaintMapper.selectList(
            new LambdaQueryWrapper<Complaint>().orderByDesc(Complaint::getCreateTime));
        List<Map<String, Object>> result = new ArrayList<>();
        for (Complaint c : complaints) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("complainantId", c.getComplainantId());
            map.put("defendantId", c.getDefendantId());
            map.put("productId", c.getProductId());
            map.put("reason", c.getReason());
            map.put("status", c.getStatus());
            map.put("createTime", c.getCreateTime());
            User complainant = userMapper.selectById(c.getComplainantId());
            if (complainant != null) {
                map.put("complainantName", complainant.getName());
            }
            User defendant = userMapper.selectById(c.getDefendantId());
            if (defendant != null) {
                map.put("defendantName", defendant.getName());
                map.put("defendantCreditScore", defendant.getCreditScore());
            }
            result.add(map);
        }
        return result;
    }

    @Transactional
    public void processComplaint(Long id) {
        Complaint c = complaintMapper.selectById(id);
        // 仅对待审核(status=0)的投诉处理，处理后置为已处理(status=1)；已处理的不会重复扣分，保证幂等
        if (c != null && c.getStatus() == 0) {
            c.setStatus(1);
            complaintMapper.updateById(c);

            User defendant = userMapper.selectById(c.getDefendantId());
            if (defendant != null) {
                int newScore = Math.max(0, (defendant.getCreditScore() != null ? defendant.getCreditScore() : 100) - 5);
                defendant.setCreditScore(newScore);
                userMapper.updateById(defendant);
            }
        }
    }

    @Transactional
    public void rejectComplaint(Long id) {
        Complaint c = complaintMapper.selectById(id);
        if (c != null && c.getStatus() == 0) {
            c.setStatus(2);
            complaintMapper.updateById(c);
        }
    }

    public Map<String, Object> getComplaintChatRecords(Long id) {
        Complaint c = complaintMapper.selectById(id);
        if (c == null) {
            throw new RuntimeException("投诉记录不存在");
        }

        User complainant = userMapper.selectById(c.getComplainantId());
        User defendant = userMapper.selectById(c.getDefendantId());
        String complainantName = complainant != null ? complainant.getName() : "";
        String defendantName = defendant != null ? defendant.getName() : "";

        Map<String, Object> result = new HashMap<>();
        result.put("id", c.getId());
        result.put("complainantId", c.getComplainantId());
        result.put("complainantName", complainantName);
        result.put("defendantId", c.getDefendantId());
        result.put("defendantName", defendantName);
        result.put("productId", c.getProductId());
        result.put("reason", c.getReason());
        result.put("status", c.getStatus());
        result.put("createTime", c.getCreateTime());

        ChatConversation conversation = findComplaintConversation(c);
        List<Map<String, Object>> messages = new ArrayList<>();
        if (conversation != null) {
            result.put("conversationId", conversation.getId());
            List<ChatMessage> list = chatMessageMapper.selectList(
                new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getConversationId, conversation.getId())
                    .orderByAsc(ChatMessage::getCreateTime));
            for (ChatMessage msg : list) {
                Map<String, Object> item = new HashMap<>();
                boolean fromComplainant = msg.getSenderId().equals(c.getComplainantId());
                item.put("id", msg.getId());
                item.put("senderId", msg.getSenderId());
                item.put("senderName", fromComplainant ? complainantName : defendantName);
                item.put("senderRole", fromComplainant ? "complainant" : "defendant");
                item.put("content", msg.getContent());
                item.put("msgType", msg.getMsgType());
                item.put("createTime", msg.getCreateTime() != null ? msg.getCreateTime().format(CHAT_TIME_FORMATTER) : "");
                messages.add(item);
            }
        }
        result.put("messages", messages);
        return result;
    }

    private ChatConversation findComplaintConversation(Complaint c) {
        if (c.getProductId() != null) {
            List<ChatConversation> exactList = conversationMapper.selectList(
                baseConversationWrapper(c)
                    .eq(ChatConversation::getProductId, c.getProductId())
                    .last("LIMIT 1"));
            if (!exactList.isEmpty()) {
                return exactList.get(0);
            }
        }
        List<ChatConversation> list = conversationMapper.selectList(
            baseConversationWrapper(c)
                .orderByDesc(ChatConversation::getLastTime)
                .orderByDesc(ChatConversation::getCreateTime)
                .last("LIMIT 1"));
        return list.isEmpty() ? null : list.get(0);
    }

    private LambdaQueryWrapper<ChatConversation> baseConversationWrapper(Complaint c) {
        return new LambdaQueryWrapper<ChatConversation>()
            .and(wrapper -> wrapper
                .eq(ChatConversation::getUser1Id, c.getComplainantId())
                .eq(ChatConversation::getUser2Id, c.getDefendantId())
                .or()
                .eq(ChatConversation::getUser1Id, c.getDefendantId())
                .eq(ChatConversation::getUser2Id, c.getComplainantId()));
    }

    public int getCreditScore(Long userId) {
        User user = userMapper.selectById(userId);
        if (user != null && user.getCreditScore() != null) {
            return user.getCreditScore();
        }
        return 100;
    }

    public boolean canTrade(Long userId) {
        return getCreditScore(userId) >= 85;
    }
}

package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.entity.Complaint;
import com.campus.entity.User;
import com.campus.mapper.ComplaintMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional
    public void submitComplaint(Long complainantId, Long defendantId, Long productId, String reason) {
        Complaint complaint = new Complaint();
        complaint.setComplainantId(complainantId);
        complaint.setDefendantId(defendantId);
        complaint.setProductId(productId);
        complaint.setReason(reason);
        complaint.setStatus(0);
        complaintMapper.insert(complaint);

        User defendant = userMapper.selectById(defendantId);
        if (defendant != null) {
            int newScore = Math.max(0, (defendant.getCreditScore() != null ? defendant.getCreditScore() : 100) - 5);
            defendant.setCreditScore(newScore);
            userMapper.updateById(defendant);
        }
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
        if (c != null && c.getStatus() == 0) {
            c.setStatus(1);
            complaintMapper.updateById(c);
        }
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

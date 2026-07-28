package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.entity.Complaint;
import com.campus.entity.User;
import com.campus.mapper.ComplaintMapper;
import com.campus.mapper.UserMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Component
public class CreditRecoveryService {

    private static final Logger log = LoggerFactory.getLogger(CreditRecoveryService.class);

    @Autowired
    private ComplaintMapper complaintMapper;

    @Autowired
    private UserMapper userMapper;

    @Scheduled(cron = "0 0 3 * * ?")
    @Transactional
    public void recoverCredit() {
        LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);
        LambdaQueryWrapper<Complaint> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Complaint::getStatus, 1)
               .le(Complaint::getCreateTime, sevenDaysAgo);
        List<Complaint> processed = complaintMapper.selectList(wrapper);

        Set<Long> defendantIds = new HashSet<>();
        for (Complaint c : processed) {
            defendantIds.add(c.getDefendantId());
        }

        if (defendantIds.isEmpty()) {
            return;
        }

        int recovered = 0;
        for (Long userId : defendantIds) {
            User user = userMapper.selectById(userId);
            if (user != null && user.getCreditScore() != null && user.getCreditScore() < 100) {
                int newScore = Math.min(100, user.getCreditScore() + 5);
                user.setCreditScore(newScore);
                userMapper.updateById(user);
                recovered++;
            }
        }

        if (recovered > 0) {
            log.info("信誉分恢复: {} 名用户获得+5分", recovered);
        }
    }
}

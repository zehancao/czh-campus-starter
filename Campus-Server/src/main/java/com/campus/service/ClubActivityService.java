package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.dto.ClubActivityVO;
import com.campus.entity.ActivityRegistration;
import com.campus.entity.ClubActivity;
import com.campus.entity.User;
import com.campus.mapper.ActivityRegistrationMapper;
import com.campus.mapper.ClubActivityMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
public class ClubActivityService {

    @Autowired
    private ClubActivityMapper clubActivityMapper;

    @Autowired
    private ActivityRegistrationMapper activityRegistrationMapper;

    @Autowired
    private UserMapper userMapper;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public ClubActivity publish(Long userId, ClubActivity activity) {
        activity.setUserId(userId);
        activity.setCurrentParticipants(0);
        activity.setStatus(1);
        clubActivityMapper.insert(activity);
        return activity;
    }

    public List<ClubActivityVO> getList(String club, Integer status, Long userId) {
        cleanExpiredActivities();
        LambdaQueryWrapper<ClubActivity> wrapper = new LambdaQueryWrapper<>();
        if (club != null && !club.isEmpty()) {
            wrapper.eq(ClubActivity::getClub, club);
        }
        if (status != null) {
            wrapper.eq(ClubActivity::getStatus, status);
        }
        wrapper.orderByDesc(ClubActivity::getActivityTime);
        List<ClubActivity> list = clubActivityMapper.selectList(wrapper);

        List<ClubActivityVO> result = new ArrayList<>();
        for (ClubActivity a : list) {
            result.add(toVO(a, userId));
        }
        return result;
    }

    public ClubActivityVO getDetail(Long id, Long userId) {
        ClubActivity a = clubActivityMapper.selectById(id);
        if (a == null) return null;
        return toVO(a, userId);
    }

    public synchronized boolean register(Long userId, Long activityId) {
        ClubActivity a = clubActivityMapper.selectById(activityId);
        if (a == null || a.getStatus() != 1) return false;

        LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
        w.eq(ActivityRegistration::getActivityId, activityId)
         .eq(ActivityRegistration::getUserId, userId);
        if (activityRegistrationMapper.selectCount(w) > 0) return false;

        if (a.getCurrentParticipants() >= a.getMaxParticipants()) {
            a.setStatus(2);
            clubActivityMapper.updateById(a);
            return false;
        }

        ActivityRegistration reg = new ActivityRegistration();
        reg.setActivityId(activityId);
        reg.setUserId(userId);
        reg.setRegisterTime(LocalDateTime.now());
        activityRegistrationMapper.insert(reg);

        a.setCurrentParticipants(a.getCurrentParticipants() + 1);
        if (a.getCurrentParticipants() >= a.getMaxParticipants()) {
            a.setStatus(2);
        }
        clubActivityMapper.updateById(a);
        return true;
    }

    public boolean cancelRegistration(Long userId, Long activityId) {
        LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
        w.eq(ActivityRegistration::getActivityId, activityId)
         .eq(ActivityRegistration::getUserId, userId);
        ActivityRegistration reg = activityRegistrationMapper.selectOne(w);
        if (reg == null) return false;

        activityRegistrationMapper.deleteById(reg.getId());

        ClubActivity a = clubActivityMapper.selectById(activityId);
        if (a != null) {
            a.setCurrentParticipants(Math.max(0, a.getCurrentParticipants() - 1));
            if (a.getStatus() == 2 && a.getCurrentParticipants() < a.getMaxParticipants()) {
                a.setStatus(1);
            }
            clubActivityMapper.updateById(a);
        }
        return true;
    }

    public List<ClubActivityVO> getMyActivities(Long userId) {
        cleanExpiredActivities();
        LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
        w.eq(ActivityRegistration::getUserId, userId);
        List<ActivityRegistration> regs = activityRegistrationMapper.selectList(w);

        List<ClubActivityVO> result = new ArrayList<>();
        for (ActivityRegistration reg : regs) {
            ClubActivity a = clubActivityMapper.selectById(reg.getActivityId());
            if (a != null && a.getActivityTime() != null && a.getActivityTime().isAfter(LocalDateTime.now())) {
                ClubActivityVO vo = toVO(a, userId);
                vo.setRegistered(true);
                result.add(vo);
            }
        }
        return result;
    }

    public void cleanExpiredActivities() {
        LambdaQueryWrapper<ClubActivity> wrapper = new LambdaQueryWrapper<>();
        wrapper.lt(ClubActivity::getActivityTime, LocalDateTime.now());
        List<ClubActivity> expired = clubActivityMapper.selectList(wrapper);
        for (ClubActivity a : expired) {
            LambdaQueryWrapper<ActivityRegistration> rw = new LambdaQueryWrapper<>();
            rw.eq(ActivityRegistration::getActivityId, a.getId());
            activityRegistrationMapper.delete(rw);
            clubActivityMapper.deleteById(a.getId());
        }
    }

    private ClubActivityVO toVO(ClubActivity a, Long userId) {
        ClubActivityVO vo = new ClubActivityVO();
        vo.setId(a.getId());
        vo.setUserId(a.getUserId());
        User user = userMapper.selectById(a.getUserId());
        if (user != null) vo.setUserName(user.getName());
        vo.setClub(a.getClub());
        vo.setTitle(a.getTitle());
        vo.setDescription(a.getDescription());
        vo.setVenue(a.getVenue());
        vo.setActivityTime(a.getActivityTime() != null ? a.getActivityTime().format(FMT) : "");
        vo.setMaxParticipants(a.getMaxParticipants());
        vo.setCurrentParticipants(a.getCurrentParticipants());
        vo.setStatus(a.getStatus());
        vo.setCoverImage(a.getCoverImage());
        vo.setCreateTime(a.getCreateTime() != null ? a.getCreateTime().format(FMT) : "");

        if (userId != null) {
            LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
            w.eq(ActivityRegistration::getActivityId, a.getId())
             .eq(ActivityRegistration::getUserId, userId);
            vo.setRegistered(activityRegistrationMapper.selectCount(w) > 0);
        }

        LambdaQueryWrapper<ActivityRegistration> pw = new LambdaQueryWrapper<>();
        pw.eq(ActivityRegistration::getActivityId, a.getId());
        List<ActivityRegistration> regs = activityRegistrationMapper.selectList(pw);
        List<String> names = new ArrayList<>();
        for (ActivityRegistration reg : regs) {
            User u = userMapper.selectById(reg.getUserId());
            if (u != null) names.add(u.getName());
        }
        vo.setParticipantNames(names);
        return vo;
    }
}

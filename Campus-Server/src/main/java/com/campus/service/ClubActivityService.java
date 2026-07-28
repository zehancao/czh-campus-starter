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
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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
        LambdaQueryWrapper<ClubActivity> wrapper = new LambdaQueryWrapper<>();
        if (club != null && !club.isEmpty()) {
            wrapper.eq(ClubActivity::getClub, club);
        }
        if (status != null) {
            wrapper.eq(ClubActivity::getStatus, status);
        }
        wrapper.ge(ClubActivity::getActivityTime, LocalDateTime.now());
        wrapper.orderByDesc(ClubActivity::getActivityTime);
        List<ClubActivity> list = clubActivityMapper.selectList(wrapper);

        return toVOList(list, userId);
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

    public boolean delete(Long userId, Long activityId) {
        ClubActivity a = clubActivityMapper.selectById(activityId);
        if (a == null || !a.getUserId().equals(userId)) return false;
        LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
        w.eq(ActivityRegistration::getActivityId, activityId);
        activityRegistrationMapper.delete(w);
        clubActivityMapper.deleteById(activityId);
        return true;
    }

    public List<ClubActivityVO> getMyPublishedActivities(Long userId) {
        LambdaQueryWrapper<ClubActivity> w = new LambdaQueryWrapper<>();
        w.eq(ClubActivity::getUserId, userId);
        w.orderByDesc(ClubActivity::getCreateTime);
        List<ClubActivity> activities = clubActivityMapper.selectList(w);
        return toVOList(activities, userId);
    }

    public List<ClubActivityVO> getMyActivities(Long userId) {
        LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
        w.eq(ActivityRegistration::getUserId, userId);
        List<ActivityRegistration> regs = activityRegistrationMapper.selectList(w);

        Set<Long> activityIds = new HashSet<>();
        for (ActivityRegistration reg : regs) {
            activityIds.add(reg.getActivityId());
        }
        Map<Long, ClubActivity> activityMap = new HashMap<>();
        if (!activityIds.isEmpty()) {
            for (ClubActivity a : clubActivityMapper.selectBatchIds(activityIds)) {
                activityMap.put(a.getId(), a);
            }
        }

        List<ClubActivity> activities = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        for (ActivityRegistration reg : regs) {
            ClubActivity a = activityMap.get(reg.getActivityId());
            if (a != null && a.getActivityTime() != null && a.getActivityTime().isAfter(now)) {
                activities.add(a);
            }
        }
        return toVOList(activities, userId);
    }

    private ClubActivityVO toVO(ClubActivity a, Long userId) {
        return toVOList(Collections.singletonList(a), userId).get(0);
    }

    private ClubActivityVO toVO(ClubActivity a, Long userId, Map<Long, User> userMap,
                                Set<Long> registeredActivityIds, List<ActivityRegistration> regs) {
        ClubActivityVO vo = new ClubActivityVO();
        vo.setId(a.getId());
        vo.setUserId(a.getUserId());
        User user = a.getUserId() != null ? userMap.get(a.getUserId()) : null;
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

        vo.setRegistered(registeredActivityIds.contains(a.getId()));

        List<String> names = new ArrayList<>();
        for (ActivityRegistration reg : regs) {
            User u = reg.getUserId() != null ? userMap.get(reg.getUserId()) : null;
            if (u != null) names.add(u.getName());
        }
        vo.setParticipantNames(names);
        return vo;
    }

    private List<ClubActivityVO> toVOList(List<ClubActivity> list, Long userId) {
        List<ClubActivityVO> result = new ArrayList<>();
        if (list.isEmpty()) return result;

        Set<Long> userIds = new HashSet<>();
        Set<Long> activityIds = new HashSet<>();
        for (ClubActivity a : list) {
            if (a.getUserId() != null) userIds.add(a.getUserId());
            activityIds.add(a.getId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Map<Long, List<ActivityRegistration>> regsByActivity = new HashMap<>();
        if (!activityIds.isEmpty()) {
            LambdaQueryWrapper<ActivityRegistration> w = new LambdaQueryWrapper<>();
            w.in(ActivityRegistration::getActivityId, activityIds);
            for (ActivityRegistration r : activityRegistrationMapper.selectList(w)) {
                regsByActivity.computeIfAbsent(r.getActivityId(), k -> new ArrayList<>()).add(r);
                if (r.getUserId() != null) userIds.add(r.getUserId());
            }
        }

        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Set<Long> registeredActivityIds = new HashSet<>();
        if (userId != null) {
            for (Map.Entry<Long, List<ActivityRegistration>> e : regsByActivity.entrySet()) {
                for (ActivityRegistration r : e.getValue()) {
                    if (userId.equals(r.getUserId())) {
                        registeredActivityIds.add(e.getKey());
                        break;
                    }
                }
            }
        }

        for (ClubActivity a : list) {
            List<ActivityRegistration> regs = regsByActivity.getOrDefault(a.getId(), new ArrayList<>());
            result.add(toVO(a, userId, userMap, registeredActivityIds, regs));
        }
        return result;
    }
}

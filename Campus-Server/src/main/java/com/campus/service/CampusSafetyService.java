package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.dto.SafetyContactVO;
import com.campus.dto.SafetyReportVO;
import com.campus.entity.SafetyContact;
import com.campus.entity.SafetyReport;
import com.campus.entity.User;
import com.campus.mapper.SafetyContactMapper;
import com.campus.mapper.SafetyReportMapper;
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
public class CampusSafetyService {

    @Autowired
    private SafetyReportMapper safetyReportMapper;

    @Autowired
    private SafetyContactMapper safetyContactMapper;

    @Autowired
    private UserMapper userMapper;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public SafetyReport submitReport(Long userId, SafetyReport report) {
        report.setUserId(userId);
        report.setStatus(0);
        if (report.getImages() == null || report.getImages().isEmpty()) {
            report.setImages("[]");
        }
        safetyReportMapper.insert(report);
        return report;
    }

    public List<SafetyReportVO> getList(Integer status, int page, int size) {
        LambdaQueryWrapper<SafetyReport> wrapper = new LambdaQueryWrapper<>();
        if (status != null) {
            wrapper.eq(SafetyReport::getStatus, status);
        }
        wrapper.orderByDesc(SafetyReport::getCreateTime);
        List<SafetyReport> list = safetyReportMapper.selectList(wrapper);
        int start = (page - 1) * size;
        int end = Math.min(start + size, list.size());
        if (start >= list.size()) {
            return new ArrayList<>();
        }
        return toVOList(list.subList(start, end));
    }

    public SafetyReportVO getDetail(Long reportId) {
        SafetyReport report = safetyReportMapper.selectById(reportId);
        if (report == null) return null;
        return toVOList(Collections.singletonList(report)).get(0);
    }

    public boolean handleReport(Long handlerId, Long reportId, Integer status, String remark) {
        SafetyReport report = safetyReportMapper.selectById(reportId);
        if (report == null) return false;
        report.setStatus(status);
        report.setHandlerId(handlerId);
        report.setHandleRemark(remark != null ? remark : "");
        report.setHandleTime(LocalDateTime.now());
        safetyReportMapper.updateById(report);
        return true;
    }

    public List<SafetyReportVO> getMyReports(Long userId) {
        LambdaQueryWrapper<SafetyReport> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SafetyReport::getUserId, userId);
        wrapper.orderByDesc(SafetyReport::getCreateTime);
        List<SafetyReport> list = safetyReportMapper.selectList(wrapper);
        return toVOList(list);
    }

    public List<SafetyContactVO> getContacts() {
        LambdaQueryWrapper<SafetyContact> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SafetyContact::getIsActive, 1);
        wrapper.orderByAsc(SafetyContact::getSortOrder);
        List<SafetyContact> list = safetyContactMapper.selectList(wrapper);

        List<SafetyContactVO> result = new ArrayList<>();
        for (SafetyContact c : list) {
            SafetyContactVO vo = new SafetyContactVO();
            vo.setId(c.getId());
            vo.setName(c.getName());
            vo.setPhone(c.getPhone());
            vo.setCategory(c.getCategory());
            result.add(vo);
        }
        return result;
    }

    private List<SafetyReportVO> toVOList(List<SafetyReport> list) {
        List<SafetyReportVO> result = new ArrayList<>();
        if (list.isEmpty()) return result;

        Set<Long> userIds = new HashSet<>();
        for (SafetyReport r : list) {
            userIds.add(r.getUserId());
            if (r.getHandlerId() != null) userIds.add(r.getHandlerId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        for (SafetyReport r : list) {
            SafetyReportVO vo = new SafetyReportVO();
            vo.setId(r.getId());
            vo.setUserId(r.getUserId());
            User reporter = userMap.get(r.getUserId());
            vo.setReporterName(reporter != null ? reporter.getName() : "");
            vo.setReporterPhone(reporter != null && reporter.getPhone() != null ? reporter.getPhone() : "");
            vo.setType(r.getType());
            vo.setLocation(r.getLocation() != null ? r.getLocation() : "");
            vo.setDescription(r.getDescription() != null ? r.getDescription() : "");

            List<String> images = new ArrayList<>();
            if (r.getImages() != null && !r.getImages().equals("[]")) {
                try {
                    String imgStr = r.getImages().trim();
                    if (imgStr.startsWith("[")) {
                        imgStr = imgStr.substring(1, imgStr.length() - 1);
                        if (!imgStr.isEmpty()) {
                            String[] parts = imgStr.split(",");
                            for (String p : parts) {
                                String clean = p.trim().replace("\"", "");
                                if (!clean.isEmpty()) images.add(clean);
                            }
                        }
                    }
                } catch (Exception e) {
                    // ignore parse errors
                }
            }
            vo.setImages(images);

            vo.setStatus(r.getStatus());
            vo.setHandlerId(r.getHandlerId());
            if (r.getHandlerId() != null) {
                User handler = userMap.get(r.getHandlerId());
                vo.setHandlerName(handler != null ? handler.getName() : "");
            } else {
                vo.setHandlerName("");
            }
            vo.setHandleRemark(r.getHandleRemark() != null ? r.getHandleRemark() : "");
            vo.setCreateTime(r.getCreateTime() != null ? r.getCreateTime().format(FMT) : "");
            vo.setHandleTime(r.getHandleTime() != null ? r.getHandleTime().format(FMT) : "");
            result.add(vo);
        }
        return result;
    }
}

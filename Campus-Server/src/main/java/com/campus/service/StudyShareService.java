package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.campus.dto.StudyShareVO;
import com.campus.entity.StudyShare;
import com.campus.entity.StudyShareFavorite;
import com.campus.entity.StudyShareLike;
import com.campus.entity.User;
import com.campus.mapper.StudyShareFavoriteMapper;
import com.campus.mapper.StudyShareLikeMapper;
import com.campus.mapper.StudyShareMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class StudyShareService {

    @Autowired
    private StudyShareMapper studyShareMapper;

    @Autowired
    private StudyShareLikeMapper studyShareLikeMapper;

    @Autowired
    private StudyShareFavoriteMapper studyShareFavoriteMapper;

    @Autowired
    private UserMapper userMapper;

    public List<StudyShareVO> getList(String courseName, String category, Integer page, Integer size, Long userId) {
        LambdaQueryWrapper<StudyShare> wrapper = new LambdaQueryWrapper<>();
        wrapper.ne(StudyShare::getStatus, 2);
        if (courseName != null && !courseName.isEmpty()) {
            wrapper.eq(StudyShare::getCourseName, courseName);
        }
        if (category != null && !category.isEmpty()) {
            wrapper.eq(StudyShare::getCategory, category);
        }
        wrapper.orderByDesc(StudyShare::getCreateTime);
        if (page != null && size != null && page > 0 && size > 0) {
            wrapper.last("LIMIT " + (page - 1) * size + "," + size);
        }
        List<StudyShare> list = studyShareMapper.selectList(wrapper);
        return toVOList(list, userId);
    }

    public StudyShareVO getDetail(Long shareId, Long userId) {
        StudyShare share = studyShareMapper.selectById(shareId);
        if (share == null || share.getStatus() == 2) return null;

        User user = share.getUserId() != null ? userMapper.selectById(share.getUserId()) : null;
        boolean liked = false;
        boolean favorited = false;
        if (userId != null) {
            LambdaQueryWrapper<StudyShareLike> lw = new LambdaQueryWrapper<>();
            lw.eq(StudyShareLike::getShareId, shareId)
              .eq(StudyShareLike::getUserId, userId);
            liked = studyShareLikeMapper.selectCount(lw) > 0;

            LambdaQueryWrapper<StudyShareFavorite> fw = new LambdaQueryWrapper<>();
            fw.eq(StudyShareFavorite::getShareId, shareId)
              .eq(StudyShareFavorite::getUserId, userId);
            favorited = studyShareFavoriteMapper.selectCount(fw) > 0;
        }

        return toVO(share, user, liked, favorited);
    }

    public StudyShare publish(Long userId, StudyShare share) {
        share.setUserId(userId);
        share.setStatus(0);
        share.setLikeCount(0);
        share.setFavoriteCount(0);
        share.setDownloadCount(0);
        studyShareMapper.insert(share);
        return share;
    }

    public boolean delete(Long userId, Long shareId) {
        StudyShare share = studyShareMapper.selectById(shareId);
        if (share == null || !userId.equals(share.getUserId())) return false;
        share.setStatus(2);
        studyShareMapper.updateById(share);
        return true;
    }

    public boolean like(Long userId, Long shareId) {
        LambdaQueryWrapper<StudyShareLike> w = new LambdaQueryWrapper<>();
        w.eq(StudyShareLike::getShareId, shareId)
         .eq(StudyShareLike::getUserId, userId);
        StudyShareLike existing = studyShareLikeMapper.selectOne(w);

        if (existing != null) {
            studyShareLikeMapper.deleteById(existing.getId());
            studyShareMapper.update(null, new LambdaUpdateWrapper<StudyShare>()
                    .eq(StudyShare::getId, shareId)
                    .setSql("like_count = like_count - 1"));
            return false;
        } else {
            StudyShareLike like = new StudyShareLike();
            like.setShareId(shareId);
            like.setUserId(userId);
            like.setCreateTime(LocalDateTime.now());
            studyShareLikeMapper.insert(like);
            studyShareMapper.update(null, new LambdaUpdateWrapper<StudyShare>()
                    .eq(StudyShare::getId, shareId)
                    .setSql("like_count = like_count + 1"));
            return true;
        }
    }

    public boolean favorite(Long userId, Long shareId) {
        LambdaQueryWrapper<StudyShareFavorite> w = new LambdaQueryWrapper<>();
        w.eq(StudyShareFavorite::getShareId, shareId)
         .eq(StudyShareFavorite::getUserId, userId);
        StudyShareFavorite existing = studyShareFavoriteMapper.selectOne(w);

        if (existing != null) {
            studyShareFavoriteMapper.deleteById(existing.getId());
            studyShareMapper.update(null, new LambdaUpdateWrapper<StudyShare>()
                    .eq(StudyShare::getId, shareId)
                    .setSql("favorite_count = favorite_count - 1"));
            return false;
        } else {
            StudyShareFavorite fav = new StudyShareFavorite();
            fav.setShareId(shareId);
            fav.setUserId(userId);
            fav.setCreateTime(LocalDateTime.now());
            studyShareFavoriteMapper.insert(fav);
            studyShareMapper.update(null, new LambdaUpdateWrapper<StudyShare>()
                    .eq(StudyShare::getId, shareId)
                    .setSql("favorite_count = favorite_count + 1"));
            return true;
        }
    }

    public void download(Long shareId) {
        studyShareMapper.update(null, new LambdaUpdateWrapper<StudyShare>()
                .eq(StudyShare::getId, shareId)
                .setSql("download_count = download_count + 1"));
    }

    public boolean report(Long userId, Long shareId) {
        StudyShare share = studyShareMapper.selectById(shareId);
        if (share == null) return false;
        share.setStatus(1);
        studyShareMapper.updateById(share);
        return true;
    }

    public List<StudyShareVO> getMyShares(Long userId) {
        LambdaQueryWrapper<StudyShare> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyShare::getUserId, userId)
               .ne(StudyShare::getStatus, 2)
               .orderByDesc(StudyShare::getCreateTime);
        List<StudyShare> list = studyShareMapper.selectList(wrapper);
        return toVOList(list, userId);
    }

    public List<StudyShareVO> getMyFavorites(Long userId) {
        LambdaQueryWrapper<StudyShareFavorite> fw = new LambdaQueryWrapper<>();
        fw.eq(StudyShareFavorite::getUserId, userId);
        List<StudyShareFavorite> favorites = studyShareFavoriteMapper.selectList(fw);

        if (favorites.isEmpty()) return new ArrayList<>();

        Set<Long> shareIds = new HashSet<>();
        for (StudyShareFavorite f : favorites) {
            shareIds.add(f.getShareId());
        }

        LambdaQueryWrapper<StudyShare> wrapper = new LambdaQueryWrapper<>();
        wrapper.in(StudyShare::getId, shareIds)
               .ne(StudyShare::getStatus, 2)
               .orderByDesc(StudyShare::getCreateTime);
        List<StudyShare> list = studyShareMapper.selectList(wrapper);
        return toVOList(list, userId);
    }

    private List<StudyShareVO> toVOList(List<StudyShare> list, Long userId) {
        List<StudyShareVO> result = new ArrayList<>();
        if (list.isEmpty()) return result;

        Set<Long> userIds = new HashSet<>();
        Set<Long> shareIds = new HashSet<>();
        for (StudyShare s : list) {
            if (s.getUserId() != null) userIds.add(s.getUserId());
            shareIds.add(s.getId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Set<Long> likedShareIds = new HashSet<>();
        Set<Long> favoritedShareIds = new HashSet<>();
        if (userId != null && !shareIds.isEmpty()) {
            LambdaQueryWrapper<StudyShareLike> lw = new LambdaQueryWrapper<>();
            lw.eq(StudyShareLike::getUserId, userId)
              .in(StudyShareLike::getShareId, shareIds);
            for (StudyShareLike l : studyShareLikeMapper.selectList(lw)) {
                likedShareIds.add(l.getShareId());
            }

            LambdaQueryWrapper<StudyShareFavorite> fw = new LambdaQueryWrapper<>();
            fw.eq(StudyShareFavorite::getUserId, userId)
              .in(StudyShareFavorite::getShareId, shareIds);
            for (StudyShareFavorite f : studyShareFavoriteMapper.selectList(fw)) {
                favoritedShareIds.add(f.getShareId());
            }
        }

        for (StudyShare s : list) {
            User u = s.getUserId() != null ? userMap.get(s.getUserId()) : null;
            boolean liked = likedShareIds.contains(s.getId());
            boolean favorited = favoritedShareIds.contains(s.getId());
            result.add(toVO(s, u, liked, favorited));
        }
        return result;
    }

    private StudyShareVO toVO(StudyShare share, User user, boolean liked, boolean favorited) {
        StudyShareVO vo = new StudyShareVO();
        vo.setId(share.getId());
        vo.setUserId(share.getUserId());
        vo.setUploaderName(user != null ? user.getName() : "未知用户");
        vo.setUploaderAvatar(user != null ? user.getAvatar() : "");
        vo.setTitle(share.getTitle());
        vo.setDescription(share.getDescription());
        vo.setCourseName(share.getCourseName());
        vo.setCategory(share.getCategory());
        vo.setFileUrl(share.getFileUrl());
        vo.setFileType(share.getFileType());
        vo.setFileSize(share.getFileSize());
        vo.setCoverImage(share.getCoverImage());
        vo.setLikeCount(share.getLikeCount());
        vo.setFavoriteCount(share.getFavoriteCount());
        vo.setDownloadCount(share.getDownloadCount());
        vo.setLiked(liked);
        vo.setFavorited(favorited);
        vo.setStatus(share.getStatus());
        vo.setCreateTime(share.getCreateTime());
        return vo;
    }
}

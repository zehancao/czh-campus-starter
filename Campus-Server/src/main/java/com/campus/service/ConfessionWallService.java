package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.campus.dto.ConfessionCommentVO;
import com.campus.dto.ConfessionPostVO;
import com.campus.entity.ConfessionComment;
import com.campus.entity.ConfessionLike;
import com.campus.entity.ConfessionPost;
import com.campus.entity.User;
import com.campus.mapper.ConfessionCommentMapper;
import com.campus.mapper.ConfessionLikeMapper;
import com.campus.mapper.ConfessionPostMapper;
import com.campus.mapper.UserMapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ConfessionWallService {

    @Autowired
    private ConfessionPostMapper confessionPostMapper;

    @Autowired
    private ConfessionCommentMapper confessionCommentMapper;

    @Autowired
    private ConfessionLikeMapper confessionLikeMapper;

    @Autowired
    private UserMapper userMapper;

    private static final ObjectMapper JSON_MAPPER = new ObjectMapper();

    public List<ConfessionPostVO> getList(String category, Integer page, Integer size, Long userId) {
        LambdaQueryWrapper<ConfessionPost> wrapper = new LambdaQueryWrapper<>();
        wrapper.ne(ConfessionPost::getStatus, 2);
        if (category != null && !category.isEmpty()) {
            wrapper.eq(ConfessionPost::getCategory, category);
        }
        wrapper.orderByDesc(ConfessionPost::getCreateTime);
        if (page != null && size != null && page > 0 && size > 0) {
            wrapper.last("LIMIT " + (page - 1) * size + "," + size);
        }
        List<ConfessionPost> list = confessionPostMapper.selectList(wrapper);
        return toVOList(list, userId, false);
    }

    public ConfessionPostVO getDetail(Long postId, Long userId) {
        ConfessionPost post = confessionPostMapper.selectById(postId);
        if (post == null) return null;

        User user = post.getUserId() != null ? userMapper.selectById(post.getUserId()) : null;
        boolean liked = false;
        if (userId != null) {
            LambdaQueryWrapper<ConfessionLike> w = new LambdaQueryWrapper<>();
            w.eq(ConfessionLike::getPostId, postId)
             .eq(ConfessionLike::getUserId, userId);
            liked = confessionLikeMapper.selectCount(w) > 0;
        }

        LambdaQueryWrapper<ConfessionComment> cw = new LambdaQueryWrapper<>();
        cw.eq(ConfessionComment::getPostId, postId)
          .orderByAsc(ConfessionComment::getCreateTime);
        List<ConfessionComment> comments = confessionCommentMapper.selectList(cw);

        Set<Long> userIds = new HashSet<>();
        if (post.getUserId() != null) userIds.add(post.getUserId());
        for (ConfessionComment c : comments) {
            if (c.getUserId() != null) userIds.add(c.getUserId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        ConfessionPostVO vo = toPostVO(post, user, liked);

        List<ConfessionCommentVO> commentVOs = new ArrayList<>();
        for (ConfessionComment c : comments) {
            commentVOs.add(toCommentVO(c, userMap));
        }
        vo.setComments(commentVOs);
        return vo;
    }

    public ConfessionPost publish(Long userId, ConfessionPost post) {
        post.setUserId(userId);
        post.setStatus(0);
        post.setLikeCount(0);
        post.setCommentCount(0);
        if (post.getImages() == null || post.getImages().isEmpty()) {
            post.setImages("[]");
        }
        confessionPostMapper.insert(post);
        return post;
    }

    public boolean delete(Long userId, Long postId) {
        ConfessionPost post = confessionPostMapper.selectById(postId);
        if (post == null || !userId.equals(post.getUserId())) return false;
        post.setStatus(2);
        confessionPostMapper.updateById(post);
        return true;
    }

    public boolean like(Long userId, Long postId) {
        LambdaQueryWrapper<ConfessionLike> w = new LambdaQueryWrapper<>();
        w.eq(ConfessionLike::getPostId, postId)
         .eq(ConfessionLike::getUserId, userId);
        ConfessionLike existing = confessionLikeMapper.selectOne(w);

        if (existing != null) {
            confessionLikeMapper.deleteById(existing.getId());
            confessionPostMapper.update(null, new LambdaUpdateWrapper<ConfessionPost>()
                    .eq(ConfessionPost::getId, postId)
                    .setSql("like_count = like_count - 1"));
            return false;
        } else {
            ConfessionLike like = new ConfessionLike();
            like.setPostId(postId);
            like.setUserId(userId);
            like.setCreateTime(LocalDateTime.now());
            confessionLikeMapper.insert(like);
            confessionPostMapper.update(null, new LambdaUpdateWrapper<ConfessionPost>()
                    .eq(ConfessionPost::getId, postId)
                    .setSql("like_count = like_count + 1"));
            return true;
        }
    }

    public ConfessionComment comment(Long userId, Long postId, String content, Integer isAnonymous) {
        ConfessionComment c = new ConfessionComment();
        c.setPostId(postId);
        c.setUserId(userId);
        c.setContent(content);
        c.setIsAnonymous(isAnonymous != null ? isAnonymous : 0);
        c.setCreateTime(LocalDateTime.now());
        confessionCommentMapper.insert(c);

        confessionPostMapper.update(null, new LambdaUpdateWrapper<ConfessionPost>()
                .eq(ConfessionPost::getId, postId)
                .setSql("comment_count = comment_count + 1"));
        return c;
    }

    public boolean report(Long userId, Long postId) {
        ConfessionPost post = confessionPostMapper.selectById(postId);
        if (post == null) return false;
        post.setStatus(1);
        confessionPostMapper.updateById(post);
        return true;
    }

    public List<ConfessionPostVO> getMyPosts(Long userId) {
        LambdaQueryWrapper<ConfessionPost> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ConfessionPost::getUserId, userId)
               .ne(ConfessionPost::getStatus, 2)
               .orderByDesc(ConfessionPost::getCreateTime);
        List<ConfessionPost> list = confessionPostMapper.selectList(wrapper);
        return toVOList(list, userId, false);
    }

    private List<ConfessionPostVO> toVOList(List<ConfessionPost> list, Long userId, boolean withComments) {
        List<ConfessionPostVO> result = new ArrayList<>();
        if (list.isEmpty()) return result;

        Set<Long> userIds = new HashSet<>();
        Set<Long> postIds = new HashSet<>();
        for (ConfessionPost p : list) {
            if (p.getUserId() != null) userIds.add(p.getUserId());
            postIds.add(p.getId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Set<Long> likedPostIds = new HashSet<>();
        if (userId != null && !postIds.isEmpty()) {
            LambdaQueryWrapper<ConfessionLike> w = new LambdaQueryWrapper<>();
            w.eq(ConfessionLike::getUserId, userId)
             .in(ConfessionLike::getPostId, postIds);
            for (ConfessionLike l : confessionLikeMapper.selectList(w)) {
                likedPostIds.add(l.getPostId());
            }
        }

        for (ConfessionPost p : list) {
            User u = p.getUserId() != null ? userMap.get(p.getUserId()) : null;
            boolean liked = likedPostIds.contains(p.getId());
            result.add(toPostVO(p, u, liked));
        }
        return result;
    }

    private ConfessionPostVO toPostVO(ConfessionPost post, User user, boolean liked) {
        ConfessionPostVO vo = new ConfessionPostVO();
        vo.setId(post.getId());
        vo.setUserId(post.getUserId());
        if (post.getIsAnonymous() != null && post.getIsAnonymous() == 1) {
            vo.setPublisherName("匿名用户");
            vo.setPublisherAvatar("");
        } else {
            vo.setPublisherName(user != null ? user.getName() : "未知用户");
            vo.setPublisherAvatar(user != null ? user.getAvatar() : "");
        }
        vo.setContent(post.getContent());
        vo.setImages(parseImages(post.getImages()));
        vo.setCategory(post.getCategory());
        vo.setIsAnonymous(post.getIsAnonymous());
        vo.setLikeCount(post.getLikeCount());
        vo.setCommentCount(post.getCommentCount());
        vo.setLiked(liked);
        vo.setStatus(post.getStatus());
        vo.setCreateTime(post.getCreateTime());
        vo.setComments(new ArrayList<>());
        return vo;
    }

    private ConfessionCommentVO toCommentVO(ConfessionComment comment, Map<Long, User> userMap) {
        ConfessionCommentVO vo = new ConfessionCommentVO();
        vo.setId(comment.getId());
        vo.setUserId(comment.getUserId());
        if (comment.getIsAnonymous() != null && comment.getIsAnonymous() == 1) {
            vo.setNickname("匿名用户");
            vo.setAvatar("");
        } else {
            User u = comment.getUserId() != null ? userMap.get(comment.getUserId()) : null;
            vo.setNickname(u != null ? u.getName() : "未知用户");
            vo.setAvatar(u != null ? u.getAvatar() : "");
        }
        vo.setContent(comment.getContent());
        vo.setIsAnonymous(comment.getIsAnonymous());
        vo.setCreateTime(comment.getCreateTime());
        return vo;
    }

    private List<String> parseImages(String images) {
        if (images == null || images.isEmpty() || "[]".equals(images)) {
            return new ArrayList<>();
        }
        try {
            return JSON_MAPPER.readValue(images, new TypeReference<List<String>>() {});
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }
}

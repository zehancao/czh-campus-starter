package com.campus.dto;

import java.time.LocalDateTime;
import java.util.List;

public class ConfessionPostVO {
    private Long id;
    private Long userId;
    private String publisherName;
    private String publisherAvatar;
    private String content;
    private List<String> images;
    private String category;
    private Integer isAnonymous;
    private Integer likeCount;
    private Integer commentCount;
    private Boolean liked;
    private Integer status;
    private LocalDateTime createTime;
    private List<ConfessionCommentVO> comments;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getPublisherName() { return publisherName; }
    public void setPublisherName(String publisherName) { this.publisherName = publisherName; }
    public String getPublisherAvatar() { return publisherAvatar; }
    public void setPublisherAvatar(String publisherAvatar) { this.publisherAvatar = publisherAvatar; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public List<String> getImages() { return images; }
    public void setImages(List<String> images) { this.images = images; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Integer getIsAnonymous() { return isAnonymous; }
    public void setIsAnonymous(Integer isAnonymous) { this.isAnonymous = isAnonymous; }
    public Integer getLikeCount() { return likeCount; }
    public void setLikeCount(Integer likeCount) { this.likeCount = likeCount; }
    public Integer getCommentCount() { return commentCount; }
    public void setCommentCount(Integer commentCount) { this.commentCount = commentCount; }
    public Boolean getLiked() { return liked; }
    public void setLiked(Boolean liked) { this.liked = liked; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
    public List<ConfessionCommentVO> getComments() { return comments; }
    public void setComments(List<ConfessionCommentVO> comments) { this.comments = comments; }
}

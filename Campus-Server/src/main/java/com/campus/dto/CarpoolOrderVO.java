package com.campus.dto;

import java.util.List;

public class CarpoolOrderVO {
    private Long id;
    private Long userId;
    private String publisherName;
    private String publisherAvatar;
    private String departure;
    private String destination;
    private String departureTime;
    private Integer maxPassengers;
    private Integer currentPassengers;
    private String contactPhone;
    private String remark;
    private Integer status;
    private Boolean joined;
    private String createTime;
    private List<PassengerVO> passengers;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getPublisherName() { return publisherName; }
    public void setPublisherName(String publisherName) { this.publisherName = publisherName; }
    public String getPublisherAvatar() { return publisherAvatar; }
    public void setPublisherAvatar(String publisherAvatar) { this.publisherAvatar = publisherAvatar; }
    public String getDeparture() { return departure; }
    public void setDeparture(String departure) { this.departure = departure; }
    public String getDestination() { return destination; }
    public void setDestination(String destination) { this.destination = destination; }
    public String getDepartureTime() { return departureTime; }
    public void setDepartureTime(String departureTime) { this.departureTime = departureTime; }
    public Integer getMaxPassengers() { return maxPassengers; }
    public void setMaxPassengers(Integer maxPassengers) { this.maxPassengers = maxPassengers; }
    public Integer getCurrentPassengers() { return currentPassengers; }
    public void setCurrentPassengers(Integer currentPassengers) { this.currentPassengers = currentPassengers; }
    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }
    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Boolean getJoined() { return joined; }
    public void setJoined(Boolean joined) { this.joined = joined; }
    public String getCreateTime() { return createTime; }
    public void setCreateTime(String createTime) { this.createTime = createTime; }
    public List<PassengerVO> getPassengers() { return passengers; }
    public void setPassengers(List<PassengerVO> passengers) { this.passengers = passengers; }
}

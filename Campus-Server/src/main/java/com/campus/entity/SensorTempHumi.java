package com.campus.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("sensor_temp_humi")
public class SensorTempHumi {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Double temp;
    private Double humidity;
    private Double light;
    private String deviceId;
    private java.time.LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Double getTemp() { return temp; }
    public void setTemp(Double temp) { this.temp = temp; }
    public Double getHumidity() { return humidity; }
    public void setHumidity(Double humidity) { this.humidity = humidity; }
    public Double getLight() { return light; }
    public void setLight(Double light) { this.light = light; }
    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }
    public java.time.LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(java.time.LocalDateTime createTime) { this.createTime = createTime; }
}

package com.campus.dto;

public class ScheduleVO {
    private Long id;
    private String courseName;
    private String classroom;
    private Integer dayOfWeek;
    private Integer startSection;
    private Integer endSection;
    private Integer startWeek;
    private Integer endWeek;
    private String weekParity;
    private String teacherName;
    private String source;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCourseName() { return courseName; }
    public void setCourseName(String courseName) { this.courseName = courseName; }
    public String getClassroom() { return classroom; }
    public void setClassroom(String classroom) { this.classroom = classroom; }
    public Integer getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(Integer dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    public Integer getStartSection() { return startSection; }
    public void setStartSection(Integer startSection) { this.startSection = startSection; }
    public Integer getEndSection() { return endSection; }
    public void setEndSection(Integer endSection) { this.endSection = endSection; }
    public Integer getStartWeek() { return startWeek; }
    public void setStartWeek(Integer startWeek) { this.startWeek = startWeek; }
    public Integer getEndWeek() { return endWeek; }
    public void setEndWeek(Integer endWeek) { this.endWeek = endWeek; }
    public String getWeekParity() { return weekParity; }
    public void setWeekParity(String weekParity) { this.weekParity = weekParity; }
    public String getTeacherName() { return teacherName; }
    public void setTeacherName(String teacherName) { this.teacherName = teacherName; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}

package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.dto.AnnouncementRequest;
import com.campus.dto.BatchClassRequest;
import com.campus.dto.ClassVO;
import com.campus.dto.ProductVO;
import com.campus.dto.SemesterVO;
import com.campus.dto.TimetableVO;
import com.campus.entity.*;
import com.campus.mapper.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
public class AdminService {

    @Autowired
    private SemesterMapper semesterMapper;

    @Autowired
    private ClassMapper classMapper;

    @Autowired
    private ClassTimetableMapper classTimetableMapper;

    @Autowired
    private AnnouncementMapper announcementMapper;

    @Autowired
    private CollegeMapper collegeMapper;

    @Autowired
    private MajorMapper majorMapper;

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private LostFoundMapper lostFoundMapper;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private static final String[] SCHEDULE_COLORS = {
            "#4A90D9", "#50C878", "#FF6B6B", "#FFB347", "#9B59B6",
            "#1ABC9C", "#E74C3C", "#3498DB", "#F39C12", "#2ECC71"
    };

    public List<SemesterVO> getSemesters() {
        List<Semester> list = semesterMapper.selectList(
                new LambdaQueryWrapper<Semester>().orderByDesc(Semester::getIsCurrent).orderByDesc(Semester::getStartDate));
        List<SemesterVO> result = new ArrayList<>();
        for (Semester s : list) {
            SemesterVO vo = new SemesterVO();
            vo.setId(s.getId());
            vo.setName(s.getName());
            vo.setStartDate(s.getStartDate() != null ? s.getStartDate().format(FORMATTER) : "");
            vo.setEndDate(s.getEndDate() != null ? s.getEndDate().format(FORMATTER) : "");
            vo.setWeekCount(s.getWeekCount());
            vo.setIsCurrent(s.getIsCurrent());
            result.add(vo);
        }
        return result;
    }

    public void addSemester(SemesterVO vo) {
        Semester semester = new Semester();
        semester.setName(vo.getName());
        semester.setStartDate(java.time.LocalDate.parse(vo.getStartDate()));
        semester.setEndDate(java.time.LocalDate.parse(vo.getEndDate()));
        semester.setWeekCount(vo.getWeekCount());
        semester.setIsCurrent(vo.getIsCurrent() != null ? vo.getIsCurrent() : 0);
        if (semester.getIsCurrent() == 1) {
            clearCurrentSemester();
        }
        semesterMapper.insert(semester);
    }

    public void updateSemester(Long id, SemesterVO vo) {
        Semester semester = semesterMapper.selectById(id);
        if (semester == null) {
            throw new RuntimeException("学期不存在");
        }
        semester.setName(vo.getName());
        semester.setStartDate(java.time.LocalDate.parse(vo.getStartDate()));
        semester.setEndDate(java.time.LocalDate.parse(vo.getEndDate()));
        semester.setWeekCount(vo.getWeekCount());
        semester.setIsCurrent(vo.getIsCurrent() != null ? vo.getIsCurrent() : 0);
        if (semester.getIsCurrent() == 1) {
            clearCurrentSemester();
        }
        semesterMapper.updateById(semester);
    }

    public void setCurrentSemester(Long id) {
        Semester semester = semesterMapper.selectById(id);
        if (semester == null) {
            throw new RuntimeException("学期不存在");
        }
        clearCurrentSemester();
        semester.setIsCurrent(1);
        semesterMapper.updateById(semester);
    }

    public void deleteSemester(Long id) {
        semesterMapper.deleteById(id);
    }

    private void clearCurrentSemester() {
        List<Semester> currents = semesterMapper.selectList(
                new LambdaQueryWrapper<Semester>().eq(Semester::getIsCurrent, 1));
        for (Semester s : currents) {
            s.setIsCurrent(0);
            semesterMapper.updateById(s);
        }
    }

    public List<ClassVO> getClasses(String grade, Long collegeId, Long majorId) {
        LambdaQueryWrapper<Clazz> wrapper = new LambdaQueryWrapper<Clazz>()
                .orderByAsc(Clazz::getGrade, Clazz::getName);
        if (grade != null && !grade.isEmpty()) {
            wrapper.eq(Clazz::getGrade, grade);
        }
        if (majorId != null) {
            wrapper.eq(Clazz::getMajorId, majorId);
        } else if (collegeId != null) {
            List<Long> majorIds = majorMapper.selectList(
                    new LambdaQueryWrapper<Major>().eq(Major::getCollegeId, collegeId))
                    .stream().map(Major::getId).toList();
            if (majorIds.isEmpty()) {
                return new ArrayList<>();
            }
            wrapper.in(Clazz::getMajorId, majorIds);
        }
        List<Clazz> list = classMapper.selectList(wrapper);
        List<ClassVO> result = new ArrayList<>();
        for (Clazz c : list) {
            ClassVO vo = new ClassVO();
            vo.setId(c.getId());
            vo.setName(c.getName());
            vo.setCollege(c.getCollege());
            vo.setMajor(c.getMajor());
            vo.setGrade(c.getGrade());
            vo.setMajorId(c.getMajorId());
            result.add(vo);
        }
        return result;
    }

    public List<College> getColleges() {
        return collegeMapper.selectList(
                new LambdaQueryWrapper<College>().orderByAsc(College::getId));
    }

    public List<Major> getMajors(Long collegeId) {
        LambdaQueryWrapper<Major> wrapper = new LambdaQueryWrapper<Major>().orderByAsc(Major::getId);
        if (collegeId != null) {
            wrapper.eq(Major::getCollegeId, collegeId);
        }
        return majorMapper.selectList(wrapper);
    }

    public List<String> getGrades() {
        List<Clazz> list = classMapper.selectList(
                new LambdaQueryWrapper<Clazz>().select(Clazz::getGrade).groupBy(Clazz::getGrade).orderByDesc(Clazz::getGrade));
        return list.stream().map(Clazz::getGrade).toList();
    }

    public void addClass(ClassVO vo) {
        Clazz clazz = new Clazz();
        clazz.setName(vo.getName());
        clazz.setCollege(vo.getCollege());
        clazz.setMajor(vo.getMajor());
        clazz.setGrade(vo.getGrade());
        clazz.setMajorId(vo.getMajorId());
        classMapper.insert(clazz);
    }

    public int batchAddClass(BatchClassRequest req) {
        List<Long> targetMajorIds = req.getMajorIds();
        if (targetMajorIds == null || targetMajorIds.isEmpty()) {
            if (req.getCollegeIds() != null && !req.getCollegeIds().isEmpty()) {
                targetMajorIds = majorMapper.selectList(
                        new LambdaQueryWrapper<Major>().in(Major::getCollegeId, req.getCollegeIds()))
                        .stream().map(Major::getId).toList();
            } else {
                targetMajorIds = majorMapper.selectList(null).stream().map(Major::getId).toList();
            }
        }
        String shortYear = req.getGrade().length() >= 4 ? req.getGrade().substring(2) : req.getGrade();
        int count = 0;
        for (Long mid : targetMajorIds) {
            Major major = majorMapper.selectById(mid);
            if (major == null) continue;
            College college = collegeMapper.selectById(major.getCollegeId());
            String collegeName = college != null ? college.getName() : "";
            String prefix = major.getName();
            int classCount = req.getClassCount() != null ? req.getClassCount() : 2;
            for (int i = 1; i <= classCount; i++) {
                String num = i < 10 ? "0" + i : String.valueOf(i);
                String className = prefix + shortYear + num;
                Clazz clazz = new Clazz();
                clazz.setName(className);
                clazz.setCollege(collegeName);
                clazz.setMajor(major.getName());
                clazz.setGrade(req.getGrade());
                clazz.setMajorId(mid);
                classMapper.insert(clazz);
                count++;
            }
        }
        return count;
    }

    public void deleteClass(Long id) {
        classMapper.deleteById(id);
    }

    public int deleteClassByGrade(String grade) {
        List<Clazz> list = classMapper.selectList(
                new LambdaQueryWrapper<Clazz>().eq(Clazz::getGrade, grade));
        for (Clazz c : list) {
            classMapper.deleteById(c.getId());
        }
        return list.size();
    }

    public List<TimetableVO> getTimetableByClass(Long classId, Long semesterId) {
        List<ClassTimetable> list = classTimetableMapper.selectList(
                new LambdaQueryWrapper<ClassTimetable>()
                        .eq(ClassTimetable::getClassId, classId)
                        .eq(ClassTimetable::getSemesterId, semesterId)
                        .orderByAsc(ClassTimetable::getDayOfWeek, ClassTimetable::getStartSection));
        List<TimetableVO> result = new ArrayList<>();
        for (ClassTimetable ct : list) {
            result.add(toTimetableVO(ct));
        }
        return result;
    }

    public List<TimetableVO> importSchedule(MultipartFile file, Long classId, Long semesterId) throws IOException {
        List<ClassTimetable> parsed = parseExcel(file, classId, semesterId);

        classTimetableMapper.delete(
                new LambdaQueryWrapper<ClassTimetable>()
                        .eq(ClassTimetable::getClassId, classId)
                        .eq(ClassTimetable::getSemesterId, semesterId));

        int colorIndex = 0;
        for (ClassTimetable ct : parsed) {
            ct.setColor(SCHEDULE_COLORS[colorIndex % SCHEDULE_COLORS.length]);
            colorIndex++;
            classTimetableMapper.insert(ct);
        }

        return parsed.stream().map(this::toTimetableVO).toList();
    }

    private List<ClassTimetable> parseExcel(MultipartFile file, Long classId, Long semesterId) throws IOException {
        Workbook workbook = new XSSFWorkbook(file.getInputStream());
        Sheet sheet = workbook.getSheetAt(0);
        List<ClassTimetable> result = new ArrayList<>();

        int dayOfWeek = 0;
        for (Row row : sheet) {
            if (row.getRowNum() == 0) {
                continue;
            }
            Cell firstCell = row.getCell(0);
            if (firstCell != null && firstCell.getStringCellValue() != null
                    && !firstCell.getStringCellValue().trim().isEmpty()) {
                String dayStr = firstCell.getStringCellValue().trim();
                dayOfWeek = parseDayOfWeek(dayStr);
            }
            if (dayOfWeek == 0) {
                continue;
            }

            Cell sectionCell = row.getCell(1);
            Cell courseCell = row.getCell(2);
            Cell teacherCell = row.getCell(3);
            Cell classroomCell = row.getCell(4);
            Cell weekCell = row.getCell(5);
            Cell remarkCell = row.getCell(6);

            if (courseCell == null || getCellString(courseCell).isEmpty()) {
                continue;
            }

            ClassTimetable ct = new ClassTimetable();
            ct.setClassId(classId);
            ct.setSemesterId(semesterId);
            ct.setDayOfWeek(dayOfWeek);
            ct.setCourseName(getCellString(courseCell));
            ct.setTeacher(teacherCell != null ? getCellString(teacherCell) : "");
            ct.setClassroom(classroomCell != null ? getCellString(classroomCell) : "");

            int[] sections = parseSections(getCellString(sectionCell));
            ct.setStartSection(sections[0]);
            ct.setEndSection(sections[1]);

            int[] weeks = parseWeeks(getCellString(weekCell));
            ct.setStartWeek(weeks[0]);
            ct.setEndWeek(weeks[1]);

            ct.setRemark(remarkCell != null ? getCellString(remarkCell) : "");
            result.add(ct);
        }
        workbook.close();
        return result;
    }

    private int parseDayOfWeek(String dayStr) {
        return switch (dayStr) {
            case "周一", "星期一", "Mon", "Monday" -> 1;
            case "周二", "星期二", "Tue", "Tuesday" -> 2;
            case "周三", "星期三", "Wed", "Wednesday" -> 3;
            case "周四", "星期四", "Thu", "Thursday" -> 4;
            case "周五", "星期五", "Fri", "Friday" -> 5;
            case "周六", "星期六", "Sat", "Saturday" -> 6;
            case "周日", "星期日", "Sun", "Sunday" -> 7;
            default -> 0;
        };
    }

    private int[] parseSections(String sectionStr) {
        if (sectionStr == null || sectionStr.isEmpty()) {
            return new int[]{1, 2};
        }
        sectionStr = sectionStr.replaceAll("[节次]", "").trim();
        if (sectionStr.contains("-")) {
            String[] parts = sectionStr.split("-");
            return new int[]{Integer.parseInt(parts[0].trim()), Integer.parseInt(parts[1].trim())};
        }
        int n = Integer.parseInt(sectionStr);
        return new int[]{n, n};
    }

    private int[] parseWeeks(String weekStr) {
        if (weekStr == null || weekStr.isEmpty()) {
            return new int[]{1, 16};
        }
        weekStr = weekStr.replaceAll("[周次]", "").trim();
        if (weekStr.contains("-")) {
            String[] parts = weekStr.split("-");
            return new int[]{Integer.parseInt(parts[0].trim()), Integer.parseInt(parts[1].trim())};
        }
        int n = Integer.parseInt(weekStr.replaceAll("\\D", ""));
        return new int[]{n, n};
    }

    private String getCellString(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> String.valueOf((int) cell.getNumericCellValue());
            default -> "";
        };
    }

    private TimetableVO toTimetableVO(ClassTimetable ct) {
        TimetableVO vo = new TimetableVO();
        vo.setId(ct.getId());
        vo.setCourseName(ct.getCourseName());
        vo.setTeacher(ct.getTeacher());
        vo.setClassroom(ct.getClassroom());
        vo.setDayOfWeek(ct.getDayOfWeek());
        vo.setStartWeek(ct.getStartWeek());
        vo.setEndWeek(ct.getEndWeek());
        vo.setStartSection(ct.getStartSection());
        vo.setEndSection(ct.getEndSection());
        vo.setColor(ct.getColor());
        vo.setRemark(ct.getRemark());
        return vo;
    }

    public void publishAnnouncement(AnnouncementRequest req, Long publisherId) {
        Announcement announcement = new Announcement();
        announcement.setTitle(req.getTitle());
        announcement.setContent(req.getContent());
        announcement.setSummary(req.getSummary());
        announcement.setCategory(req.getCategory());
        announcement.setPublisherId(publisherId);
        announcement.setIsTop(req.getIsTop() != null ? req.getIsTop() : 0);
        announcement.setIsPublished(req.getIsPublished() != null ? req.getIsPublished() : 1);
        announcement.setPublishTime(LocalDateTime.now());
        announcement.setTargetTags(req.getTargetTags());
        announcementMapper.insert(announcement);
    }

    public void updateAnnouncement(Long id, AnnouncementRequest req) {
        Announcement announcement = announcementMapper.selectById(id);
        if (announcement == null) {
            throw new RuntimeException("公告不存在");
        }
        announcement.setTitle(req.getTitle());
        announcement.setContent(req.getContent());
        announcement.setSummary(req.getSummary());
        announcement.setCategory(req.getCategory());
        announcement.setIsTop(req.getIsTop());
        announcement.setIsPublished(req.getIsPublished());
        announcement.setTargetTags(req.getTargetTags());
        announcementMapper.updateById(announcement);
    }

    public void deleteAnnouncement(Long id) {
        announcementMapper.deleteById(id);
    }

    public List<Announcement> getAnnouncementList() {
        return announcementMapper.selectList(
                new LambdaQueryWrapper<Announcement>()
                        .orderByDesc(Announcement::getIsTop)
                         .orderByDesc(Announcement::getCreateTime));
    }

    public List<ProductVO> getPendingProducts() {
        List<Product> list = productMapper.selectPendingWithSeller();
        return toProductVOList(list);
    }

    public void approveProduct(Long productId) {
        Product product = productMapper.selectById(productId);
        if (product != null) {
            product.setStatus(1);
            productMapper.updateById(product);
        }
    }

    public void rejectProduct(Long productId) {
        Product product = productMapper.selectById(productId);
        if (product != null) {
            product.setStatus(3);
            productMapper.updateById(product);
        }
    }

    public List<User> getAllUsers() {
        return userMapper.selectList(
                new LambdaQueryWrapper<User>().orderByDesc(User::getCreateTime));
    }

    public List<LostFound> getAllLostFound() {
        return lostFoundMapper.selectList(
                new LambdaQueryWrapper<LostFound>().orderByDesc(LostFound::getCreateTime));
    }

    public List<Product> getAllProducts() {
        return productMapper.selectList(
                new LambdaQueryWrapper<Product>().orderByDesc(Product::getCreateTime));
    }

    private List<ProductVO> toProductVOList(List<Product> list) {
        List<ProductVO> result = new ArrayList<>();
        for (Product p : list) {
            ProductVO vo = new ProductVO();
            vo.setId(p.getId());
            vo.setSellerId(p.getSellerId());
            vo.setCategoryId(p.getCategoryId());
            vo.setTitle(p.getTitle());
            vo.setDescription(p.getDescription());
            vo.setPrice(p.getPrice());
            vo.setOriginalPrice(p.getOriginalPrice());
            vo.setConditionLevel(p.getConditionLevel());
            vo.setStatus(p.getStatus());
            vo.setViewCount(p.getViewCount());
            vo.setCampusLocation(p.getCampusLocation());
            if (p.getCreateTime() != null) {
                vo.setCreateTime(p.getCreateTime().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            }
            User seller = userMapper.selectById(p.getSellerId());
            if (seller != null) {
                vo.setSellerName(seller.getName());
            }
            if (p.getImages() != null && !p.getImages().isEmpty()) {
                String cleaned = p.getImages().replace("[", "").replace("]", "").replace("\"", "");
                if (!cleaned.isEmpty()) {
                    vo.setImages(cleaned.split(","));
                }
            }
            result.add(vo);
        }
        return result;
    }
}

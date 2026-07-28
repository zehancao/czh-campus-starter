package com.campus.controller;

import com.campus.common.Result;
import com.campus.entity.Clazz;
import com.campus.entity.College;
import com.campus.entity.Major;
import com.campus.entity.ProductCategory;
import com.campus.entity.SensorTempHumi;
import com.campus.service.AdminService;
import com.campus.mapper.ProductCategoryMapper;
import com.campus.mapper.SensorTempHumiMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
public class PublicController {

    @Autowired
    private AdminService adminService;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    @Autowired
    private SensorTempHumiMapper sensorTempHumiMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/colleges")
    public Result<List<College>> getColleges() {
        return Result.ok(adminService.getColleges());
    }

    @GetMapping("/majors")
    public Result<List<Major>> getMajors(@RequestParam(required = false) Long collegeId) {
        return Result.ok(adminService.getMajors(collegeId));
    }

    @GetMapping("/classes")
    public Result<List<com.campus.dto.ClassVO>> getClasses(@RequestParam(required = false) String grade,
                                                            @RequestParam(required = false) Long collegeId,
                                                            @RequestParam(required = false) Long majorId) {
        return Result.ok(adminService.getClasses(grade, collegeId, majorId));
    }

    @GetMapping("/grades")
    public Result<List<String>> getGrades() {
        return Result.ok(adminService.getGrades());
    }

    @GetMapping("/product-categories")
    public Result<List<ProductCategory>> getProductCategories() {
        List<ProductCategory> list = productCategoryMapper.selectList(
                new LambdaQueryWrapper<ProductCategory>().orderByAsc(ProductCategory::getSortOrder));
        return Result.ok(list);
    }

    /**
     * 开发板温湿度上报（串口中继脚本调用，免登录）
     * 请求体：{ "temp": 26.5, "humidity": 60.2, "deviceId": "rk2206-01" }
     */
    @PostMapping("/sensor/temphumi")
    public Result<Void> uploadTempHumi(@RequestBody Map<String, Object> body) {
        Object t = body.get("temp");
        Object h = body.get("humidity");
        if (t == null || h == null) {
            return Result.error("temp 和 humidity 必填");
        }
        SensorTempHumi s = new SensorTempHumi();
        try {
            s.setTemp(Double.valueOf(t.toString()));
            s.setHumidity(Double.valueOf(h.toString()));
        } catch (NumberFormatException e) {
            return Result.error("temp / humidity 必须是数字");
        }
        // 光照(lux)为可选字段：板子上报带 light 则记录，否则留空
        Object l = body.get("light");
        if (l != null && !l.toString().isEmpty()) {
            try {
                s.setLight(Double.valueOf(l.toString()));
            } catch (NumberFormatException e) {
                // 光照格式非法时忽略，不影响温湿度入库
            }
        }
        Object dev = body.get("deviceId");
        s.setDeviceId(dev != null ? dev.toString() : "rk2206-01");
        // id 循环：表里 id 涨到 1000 后，下一条 id=1 重新开始
        // 注意：日常有 100 条滚动清理，id 不会涨到 1000；这里主要是兜底，异常情况下重启 id 计数
        List<Map<String, Object>> maxRows = sensorTempHumiMapper.selectMaps(
                new QueryWrapper<SensorTempHumi>().select("MAX(id) AS max_id"));
        Long maxId = (maxRows != null && !maxRows.isEmpty() && maxRows.get(0).get("max_id") != null)
                ? ((Number) maxRows.get(0).get("max_id")).longValue() : null;
        if (maxId != null && maxId >= 1000) {
            sensorTempHumiMapper.delete(new LambdaQueryWrapper<SensorTempHumi>());
            jdbcTemplate.execute("ALTER TABLE sensor_temp_humi AUTO_INCREMENT = 1");
        }

        s.setCreateTime(java.time.LocalDateTime.now());
        sensorTempHumiMapper.insert(s);

        // 滚动保留最近 100 条：超出则删除最旧的若干条
        long count = sensorTempHumiMapper.selectCount(
                new LambdaQueryWrapper<SensorTempHumi>());
        if (count > 100) {
            List<SensorTempHumi> oldest = sensorTempHumiMapper.selectList(
                    new LambdaQueryWrapper<SensorTempHumi>()
                            .orderByAsc(SensorTempHumi::getCreateTime)
                            .last("LIMIT " + (count - 100)));
            if (!oldest.isEmpty()) {
                sensorTempHumiMapper.deleteBatchIds(
                        oldest.stream().map(SensorTempHumi::getId).toList());
            }
        }
        return Result.ok();
    }
}

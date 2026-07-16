package com.campus.controller;

import com.campus.common.Result;
import com.campus.mapper.UserMapper;
import com.campus.mapper.ProductMapper;
import com.campus.mapper.FavoriteMapper;
import com.campus.mapper.AnnouncementMapper;
import com.campus.mapper.LostFoundMapper;
import com.campus.mapper.ProductCategoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin/stats")
public class StatsController {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private AnnouncementMapper announcementMapper;

    @Autowired
    private LostFoundMapper lostFoundMapper;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    @GetMapping("/overview")
    public Result<Map<String, Object>> getOverview() {
        Map<String, Object> data = new HashMap<>();
        data.put("userCount", userMapper.selectCount(null));
        data.put("productCount", productMapper.selectCount(null));
        data.put("announcementCount", announcementMapper.selectCount(null));
        data.put("lostFoundCount", lostFoundMapper.selectCount(null));
        return Result.ok(data);
    }

    @GetMapping("/products-by-category")
    public Result<List<Map<String, Object>>> productsByCategory() {
        List<Map<String, Object>> result = productMapper.selectMaps(
            new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.campus.entity.Product>()
                .select("category_id, count(*) as value")
                .groupBy("category_id")
        );
        List<Map<String, Object>> formatted = new ArrayList<>();
        Map<Long, String> categoryNames = new HashMap<>();
        List<com.campus.entity.ProductCategory> categories = productCategoryMapper.selectList(null);
        for (com.campus.entity.ProductCategory cat : categories) {
            categoryNames.put(cat.getId(), cat.getName());
        }
        for (Map<String, Object> row : result) {
            Map<String, Object> item = new HashMap<>();
            Long catId = ((Number) row.get("category_id")).longValue();
            item.put("name", categoryNames.getOrDefault(catId, "未知"));
            item.put("value", row.get("value"));
            formatted.add(item);
        }
        return Result.ok(formatted);
    }

    @GetMapping("/products-by-status")
    public Result<List<Map<String, Object>>> productsByStatus() {
        List<Map<String, Object>> result = productMapper.selectMaps(
            new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.campus.entity.Product>()
                .select("status, count(*) as count")
                .groupBy("status")
        );
        List<Map<String, Object>> formatted = new ArrayList<>();
        String[] statusNames = {"下架", "上架", "已交易"};
        for (Map<String, Object> row : result) {
            Map<String, Object> item = new HashMap<>();
            int status = ((Number) row.get("status")).intValue();
            item.put("name", status >= 0 && status < statusNames.length ? statusNames[status] : "未知");
            item.put("value", row.get("count"));
            formatted.add(item);
        }
        return Result.ok(formatted);
    }

    @GetMapping("/users-by-college")
    public Result<List<Map<String, Object>>> usersByCollege() {
        List<Map<String, Object>> result = userMapper.selectMaps(
            new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.campus.entity.User>()
                .select("college as name, count(*) as value")
                .groupBy("college")
        );
        return Result.ok(result);
    }

    @GetMapping("/hometown-stats")
    public Result<List<Map<String, Object>>> hometownStats() {
        List<Map<String, Object>> result = userMapper.selectMaps(
            new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.campus.entity.User>()
                .select("hometown as name, count(*) as value")
                .ne("hometown", "")
                .isNotNull("hometown")
                .groupBy("hometown")
        );
        return Result.ok(result);
    }
}

package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.FavoriteVO;
import com.campus.service.FavoriteService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorite")
public class FavoriteController {

    @Autowired
    private FavoriteService favoriteService;

    @GetMapping("/list")
    public Result<List<FavoriteVO>> list(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        List<FavoriteVO> list = favoriteService.getMyFavorites(userId);
        return Result.ok(list);
    }

    @PostMapping("/add")
    public Result<Void> add(HttpServletRequest request, @RequestParam("productId") Long productId) {
        Long userId = (Long) request.getAttribute("userId");
        favoriteService.addFavorite(userId, productId);
        return Result.ok();
    }

    @PostMapping("/remove")
    public Result<Void> remove(HttpServletRequest request, @RequestParam("productId") Long productId) {
        Long userId = (Long) request.getAttribute("userId");
        favoriteService.removeFavorite(userId, productId);
        return Result.ok();
    }

    @GetMapping("/check")
    public Result<Boolean> check(HttpServletRequest request, @RequestParam("productId") Long productId) {
        Long userId = (Long) request.getAttribute("userId");
        boolean isFav = favoriteService.isFavorite(userId, productId);
        return Result.ok(isFav);
    }
}

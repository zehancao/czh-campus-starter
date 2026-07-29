package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.ProductVO;
import com.campus.service.BrowseHistoryService;
import com.campus.service.ProductService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/product")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private BrowseHistoryService browseHistoryService;

    @Autowired
    private com.campus.service.ComplaintService complaintService;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/list")
    public Result<List<ProductVO>> getList(
            @RequestParam(value = "categoryId", required = false) Long categoryId,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {
        return Result.ok(productService.getProductList(categoryId, page, size));
    }

    @GetMapping("/search")
    public Result<List<ProductVO>> search(
            @RequestParam("keyword") String keyword,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {
        return Result.ok(productService.searchProducts(keyword, page, size));
    }

    @GetMapping("/search-suggest")
    public Result<List<String>> searchSuggest(@RequestParam("keyword") String keyword) {
        return Result.ok(productService.searchSuggest(keyword));
    }

    @GetMapping("/{id}")
    public Result<ProductVO> getDetail(@PathVariable("id") Long id, HttpServletRequest request) {
        ProductVO vo = productService.getProductDetail(id);
        try {
            Long userId = (Long) request.getAttribute("userId");
            if (userId != null) {
                browseHistoryService.recordBrowse(userId, id);
            }
        } catch (Exception ignored) {}
        return Result.ok(vo);
    }

    @PostMapping("/publish")
    public Result<Void> publish(HttpServletRequest request, @RequestBody ProductVO vo) {
        Long userId = (Long) request.getAttribute("userId");
        if (!complaintService.canTrade(userId)) {
            return Result.error("信用分不足85，无法发布商品");
        }
        productService.publishProduct(userId, vo);
        return Result.ok();
    }

    @GetMapping("/my-products")
    public Result<List<ProductVO>> myProducts(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        List<ProductVO> list = productService.getMyProducts(userId);
        return Result.ok(list);
    }

    @PostMapping("/update-status")
    public Result<Void> updateStatus(HttpServletRequest request, @RequestParam("productId") Long productId, @RequestParam("status") Integer status) {
        Long userId = (Long) request.getAttribute("userId");
        productService.updateProductStatus(userId, productId, status);
        return Result.ok();
    }

    @PostMapping("/delete")
    public Result<Void> delete(HttpServletRequest request, @RequestParam("productId") Long productId) {
        Long userId = (Long) request.getAttribute("userId");
        productService.deleteProduct(userId, productId);
        return Result.ok();
    }

    @PostMapping("/upload-image")
    public Result<String> uploadImage(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        Set<String> ALLOWED = Set.of("jpg", "jpeg", "png", "gif", "webp");
        if (!ALLOWED.contains(ext.toLowerCase().replace(".", ""))) {
            return Result.error("不支持的文件类型");
        }
        String filename = UUID.randomUUID().toString().replace("-", "") + ext;
        File dir = new File(uploadDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        try {
            file.transferTo(new File(dir, filename));
        } catch (IOException e) {
            return Result.error("上传失败");
        }
        String url = "/uploads/" + filename;
        return Result.ok(url);
    }
}

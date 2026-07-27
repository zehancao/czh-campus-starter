package com.campus.service;

import com.campus.dto.ProductVO;
import com.campus.entity.Product;
import com.campus.entity.ProductCategory;
import com.campus.mapper.ProductMapper;
import com.campus.mapper.ProductCategoryMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Service
public class ProductService {

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    public List<ProductVO> getProductList(Long categoryId, int page, int size) {
        List<Product> list = productMapper.selectListWithSeller();
        if (categoryId != null && categoryId > 0) {
            List<Long> allowedIds = new ArrayList<>();
            allowedIds.add(categoryId);
            List<ProductCategory> children = productCategoryMapper.selectList(
                    new LambdaQueryWrapper<ProductCategory>().eq(ProductCategory::getParentId, categoryId));
            for (ProductCategory child : children) {
                allowedIds.add(child.getId());
            }
            list.removeIf(p -> !allowedIds.contains(p.getCategoryId()));
        }
        int start = (page - 1) * size;
        int end = Math.min(start + size, list.size());
        if (start >= list.size()) {
            return new ArrayList<>();
        }
        return toVOList(list.subList(start, end));
    }

    public List<ProductVO> searchProducts(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return getProductList(null, 1, Integer.MAX_VALUE);
        }
        String kw = keyword.trim().toLowerCase();
        List<Product> list = productMapper.selectSearchWithSeller(kw);
        return toVOList(list);
    }

    public List<String> searchSuggest(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return new ArrayList<>();
        }
        String kw = keyword.trim().toLowerCase();
        List<Product> list = productMapper.selectListWithSeller();
        List<String> titles = new ArrayList<>();
        for (Product p : list) {
            if (p.getTitle() != null && p.getTitle().toLowerCase().contains(kw)) {
                titles.add(p.getTitle());
            }
            if (titles.size() >= 10) break;
        }
        return titles;
    }

    public ProductVO getProductDetail(Long id) {
        LambdaUpdateWrapper<Product> uw = new LambdaUpdateWrapper<>();
        uw.eq(Product::getId, id).setSql("view_count = view_count + 1");
        productMapper.update(null, uw);
        Product product = productMapper.selectDetailById(id);
        if (product == null) {
            throw new RuntimeException("商品不存在");
        }
        return toVO(product);
    }

    public void publishProduct(Long sellerId, ProductVO vo) {
        Product product = new Product();
        product.setSellerId(sellerId);
        product.setCategoryId(vo.getCategoryId());
        product.setTitle(vo.getTitle());
        product.setDescription(vo.getDescription());
        product.setPrice(vo.getPrice());
        product.setOriginalPrice(vo.getOriginalPrice());
        product.setConditionLevel(vo.getConditionLevel());
        String[] imgs = vo.getImages();
        if (imgs != null && imgs.length > 0) {
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < imgs.length; i++) {
                if (i > 0) sb.append(",");
                sb.append("\"").append(imgs[i]).append("\"");
            }
            sb.append("]");
            product.setImages(sb.toString());
        } else {
            product.setImages(null);
        }
        product.setStatus(0);
        product.setViewCount(0);
        product.setFavoriteCount(0);
        product.setCampusLocation(vo.getCampusLocation());
        productMapper.insert(product);
    }

    public List<ProductVO> getMyProducts(Long userId) {
        List<Product> list = productMapper.selectList(
                new LambdaQueryWrapper<Product>()
                        .eq(Product::getSellerId, userId)
                        .orderByDesc(Product::getCreateTime));
        for (Product p : list) {
            if (p.getSellerName() == null) {
                p.setSellerName("");
            }
        }
        return toVOList(list);
    }

    public void updateProductStatus(Long userId, Long productId, Integer status) {
        Product product = productMapper.selectById(productId);
        if (product == null || !product.getSellerId().equals(userId)) {
            throw new RuntimeException("无权操作");
        }
        product.setStatus(status);
        productMapper.updateById(product);
    }

    public void deleteProduct(Long userId, Long productId) {
        Product product = productMapper.selectById(productId);
        if (product == null || !product.getSellerId().equals(userId)) {
            throw new RuntimeException("无权操作");
        }
        productMapper.deleteById(productId);
    }

    private List<ProductVO> toVOList(List<Product> list) {
        List<ProductVO> result = new ArrayList<>();
        for (Product p : list) {
            result.add(toVO(p));
        }
        return result;
    }

    private ProductVO toVO(Product p) {
        ProductVO vo = new ProductVO();
        vo.setId(p.getId());
        vo.setSellerId(p.getSellerId());
        vo.setSellerName(p.getSellerName());
        vo.setCategoryId(p.getCategoryId());
        if (p.getCategoryId() != null) {
            ProductCategory cat = productCategoryMapper.selectById(p.getCategoryId());
            vo.setCategoryName(cat != null ? cat.getName() : null);
        }
        vo.setTitle(p.getTitle());
        vo.setDescription(p.getDescription());
        vo.setPrice(p.getPrice());
        vo.setOriginalPrice(p.getOriginalPrice());
        vo.setConditionLevel(p.getConditionLevel());
        String imgs = p.getImages();
        String[] imgArr;
        if (imgs != null && !imgs.isEmpty()) {
            String cleaned = imgs.replace("[", "").replace("]", "").replace("\"", "");
            if (cleaned.isEmpty()) {
                imgArr = new String[]{};
            } else {
                imgArr = cleaned.split(",");
            }
        } else {
            imgArr = new String[]{};
        }
        vo.setImages(imgArr);
        vo.setStatus(p.getStatus());
        vo.setViewCount(p.getViewCount());
        vo.setCampusLocation(p.getCampusLocation());
        vo.setCreateTime(p.getCreateTime() != null ? p.getCreateTime().toString() : "");
        return vo;
    }
}

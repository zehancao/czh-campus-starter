package com.campus.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.campus.entity.Product;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface ProductMapper extends BaseMapper<Product> {

    @Select("SELECT p.*, u.name as seller_name FROM products p LEFT JOIN users u ON p.seller_id = u.id WHERE p.status = 1 ORDER BY p.create_time DESC")
    List<Product> selectListWithSeller();

    @Select("SELECT p.*, u.name as seller_name FROM products p LEFT JOIN users u ON p.seller_id = u.id WHERE p.status = 0 ORDER BY p.create_time DESC")
    List<Product> selectPendingWithSeller();

    @Select("SELECT p.*, u.name as seller_name FROM products p LEFT JOIN users u ON p.seller_id = u.id WHERE p.id = #{id}")
    Product selectDetailById(Long id);

    @Select("SELECT p.*, u.name as seller_name FROM products p LEFT JOIN users u ON p.seller_id = u.id " +
            "WHERE p.status = 1 AND (LOWER(p.title) LIKE CONCAT('%', #{kw}, '%') OR LOWER(p.description) LIKE CONCAT('%', #{kw}, '%')) " +
            "ORDER BY p.create_time DESC")
    List<Product> selectSearchWithSeller(@Param("kw") String kw);
}

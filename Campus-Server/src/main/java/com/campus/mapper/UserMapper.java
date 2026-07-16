/*package com.campus.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.campus.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper extends BaseMapper<User> {
}*/

package com.campus.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.campus.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;
import java.util.Map;

@Mapper
public interface UserMapper extends BaseMapper<User> {

    @Select("SELECT college AS name, COUNT(*) AS value, hometown FROM users GROUP BY college, hometown")
    List<Map<String, Object>> selectUserByCollege();

}

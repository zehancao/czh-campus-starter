package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.common.JwtUtil;
import com.campus.dto.LoginRequest;
import com.campus.dto.RegisterRequest;
import com.campus.dto.UserVO;
import com.campus.entity.Clazz;
import com.campus.entity.User;
import com.campus.mapper.ClassMapper;
import com.campus.mapper.UserMapper;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ClassMapper classMapper;

    @Autowired
    private JwtUtil jwtUtil;

    public Map<String, Object> login(LoginRequest req) {
        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>().eq(User::getStudentId, req.getStudentId()));
        if (user == null || !BCrypt.checkpw(req.getPassword(), user.getPassword())) {
            throw new RuntimeException("学号或密码错误");
        }
        if (user.getStatus() == 0) {
            throw new RuntimeException("账号已被禁用");
        }
        String token = jwtUtil.generateToken(user.getId(), user.getStudentId(), user.getRole());
        return Map.of("token", token, "user", toVO(user));
    }

    public void register(RegisterRequest req) {
        Long count = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getStudentId, req.getStudentId()));
        if (count > 0) {
            throw new RuntimeException("该学号已注册");
        }

        Long classId = null;
        if (req.getClassName() != null && !req.getClassName().isEmpty()) {
            Clazz clazz = classMapper.selectOne(
                    new LambdaQueryWrapper<Clazz>().eq(Clazz::getName, req.getClassName()));
            if (clazz != null) {
                classId = clazz.getId();
            } else {
                Clazz newClass = new Clazz();
                newClass.setName(req.getClassName());
                newClass.setCollege(req.getCollege());
                newClass.setMajor(req.getMajor());
                newClass.setGrade(req.getGrade());
                classMapper.insert(newClass);
                classId = newClass.getId();
            }
        }

        User user = new User();
        user.setStudentId(req.getStudentId());
        user.setName(req.getName());
        user.setPassword(BCrypt.hashpw(req.getPassword(), BCrypt.gensalt()));
        user.setPhone(req.getPhone());
        user.setGrade(req.getGrade());
        user.setCollege(req.getCollege());
        user.setMajor(req.getMajor());
        user.setClassId(classId);
        user.setClassName(req.getClassName());
        user.setHometown(req.getHometown() != null ? req.getHometown() : "");
        user.setRole("student");
        user.setCreditScore(100);
        user.setStatus(1);
        userMapper.insert(user);
    }

    public UserVO getProfile(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        return toVO(user);
    }

    private UserVO toVO(User user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setStudentId(user.getStudentId());
        vo.setName(user.getName());
        vo.setAvatar(user.getAvatar());
        vo.setCollege(user.getCollege());
        vo.setMajor(user.getMajor());
        vo.setGrade(user.getGrade());
        vo.setHometown(user.getHometown());
        vo.setPhone(user.getPhone());
        vo.setRole(user.getRole());
        vo.setCreditScore(user.getCreditScore());
        if (user.getClassId() != null) {
            Clazz clazz = classMapper.selectById(user.getClassId());
            if (clazz != null) {
                vo.setClassName(clazz.getName());
            }
        }
        return vo;
    }

    public boolean changePassword(Long userId, String oldPassword, String newPassword) {
        User user = userMapper.selectById(userId);
        if (user == null || !BCrypt.checkpw(oldPassword, user.getPassword())) {
            return false;
        }
        user.setPassword(BCrypt.hashpw(newPassword, BCrypt.gensalt()));
        userMapper.updateById(user);
        return true;
    }

    public void updateAvatar(Long userId, String avatarUrl) {
        User user = userMapper.selectById(userId);
        if (user != null) {
            user.setAvatar(avatarUrl);
            userMapper.updateById(user);
        }
    }
}

package com.campus.config;

import com.campus.common.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String uri = request.getRequestURI();
        boolean isWhitelisted = uri.startsWith("/api/user/login") || uri.startsWith("/api/user/register") || uri.startsWith("/api/public/") || uri.startsWith("/uploads/") || uri.startsWith("/api/classroom/") || uri.startsWith("/ws/") || uri.startsWith("/api/feedback/") || uri.equals("/api/product/list") || uri.equals("/api/lost-found/list") || uri.equals("/api/lost-found/detail") || (uri.startsWith("/api/product/") && !uri.equals("/api/product/publish") && !uri.equals("/api/product/upload-image") && !uri.equals("/api/product/my-products") && !uri.equals("/api/product/update-status") && !uri.equals("/api/product/delete")) || uri.startsWith("/api/admin/stats/") || uri.equals("/api/admin/announcement/list");

        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtil.validateToken(token)) {
                Long userId = jwtUtil.getUserIdFromToken(token);
                String role = jwtUtil.parseToken(token).get("role", String.class);
                request.setAttribute("userId", userId);
                request.setAttribute("role", role);
            }
        }

        if (isWhitelisted) {
            filterChain.doFilter(request, response);
            return;
        }

        if (request.getAttribute("userId") == null) {
            sendError(response, 401, "未登录");
            return;
        }

        if (uri.startsWith("/api/admin") && !"admin".equals(request.getAttribute("role"))) {
            sendError(response, 403, "无管理员权限");
            return;
        }
        filterChain.doFilter(request, response);
    }

    private void sendError(HttpServletResponse response, int code, String msg) throws IOException {
        response.setStatus(code);
        response.setContentType("application/json;charset=UTF-8");
        Map<String, Object> result = Map.of("code", code, "msg", msg);
        response.getWriter().write(objectMapper.writeValueAsString(result));
    }
}

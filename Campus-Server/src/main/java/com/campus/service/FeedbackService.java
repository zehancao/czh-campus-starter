package com.campus.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class FeedbackService {

    private static final Logger log = LoggerFactory.getLogger(FeedbackService.class);

    @Autowired
    private JavaMailSender mailSender;

    @Value("${feedback.email}")
    private String feedbackEmail;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Async
    public void sendFeedbackAsync(String userName, String contact, String content) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromEmail);
            helper.setTo(feedbackEmail);
            helper.setSubject("智能校园助手 - 用户反馈");
            String html = "<div style='padding:20px;font-family:sans-serif;'>"
                    + "<h3>用户反馈</h3>"
                    + "<p><b>用户：</b>" + escapeHtml(userName) + "</p>"
                    + "<p><b>联系方式：</b>" + escapeHtml(contact) + "</p>"
                    + "<p><b>反馈内容：</b></p>"
                    + "<div style='background:#f5f5f5;padding:12px;border-radius:8px;'>" + escapeHtml(content) + "</div>"
                    + "</div>";
            helper.setText(html, true);
            mailSender.send(message);
            log.info("反馈邮件发送成功 - 用户: {}", userName);
        } catch (Exception e) {
            log.error("反馈邮件发送失败 - 用户: {}, 错误: {}", userName, e.getMessage());
        }
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }
}

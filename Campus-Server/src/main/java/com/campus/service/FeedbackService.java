package com.campus.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class FeedbackService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${feedback.email}")
    private String feedbackEmail;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public void sendFeedback(String userName, String contact, String content) throws MessagingException {
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

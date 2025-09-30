package com.example.gps.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        // 检查users表是否存在，如果不存在则创建
        try {
            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS users (" +
                    "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                    "username VARCHAR(255), " +
                    "email VARCHAR(255), " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                    ")");
            
            // 检查是否已有测试用户，如果没有则插入
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM users WHERE id = 1", Integer.class);
            
            if (count == 0) {
                jdbcTemplate.update(
                        "INSERT INTO users (id, username, email) VALUES (1, 'testuser', 'test@example.com')");
                System.out.println("✅ 已自动创建测试用户 (ID: 1)");
            } else {
                System.out.println("✅ 测试用户已存在 (ID: 1)");
            }
        } catch (Exception e) {
            System.err.println("⚠️  数据初始化警告: " + e.getMessage());
        }
    }
} 
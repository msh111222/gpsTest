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
        System.out.println("🚀 开始初始化GPS测试数据...");
        
        try {
            // 插入一些测试GPS位置数据
            jdbcTemplate.update(
                    "INSERT IGNORE INTO gps_locations (user_id, latitude, longitude, timestamp) VALUES " +
                    "(1, 39.9042, 116.4074, NOW()), " +
                    "(1, 39.9142, 116.4174, NOW()), " +
                    "(2, 31.2304, 121.4737, NOW())");
            
            System.out.println("✅ GPS测试数据初始化完成!");
            
        } catch (Exception e) {
            System.err.println("⚠️  数据初始化警告: " + e.getMessage());
        }
    }
} 
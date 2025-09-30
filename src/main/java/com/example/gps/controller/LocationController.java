package com.example.gps.controller;

import com.example.gps.entity.Location;
import com.example.gps.service.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/location")
@CrossOrigin(origins = "*")
public class LocationController {

    @Autowired
    private LocationService locationService;

    // 提交位置信息
    @PostMapping("/submit")
    public ResponseEntity<Map<String, Object>> submitLocation(@RequestBody Location location) {
        Map<String, Object> response = new HashMap<>();
        try {
            // 单人测试，固定用户ID为1
            if (location.getUserId() == null) {
                location.setUserId(1L);
            }
            
            Location savedLocation = locationService.saveLocation(location);
            response.put("success", true);
            response.put("message", "位置信息保存成功");
            response.put("data", savedLocation);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "位置信息保存失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 获取用户位置历史
    @GetMapping("/history/{userId}")
    public ResponseEntity<Map<String, Object>> getLocationHistory(@PathVariable Long userId) {
        Map<String, Object> response = new HashMap<>();
        try {
            List<Location> locations = locationService.findByUserId(userId);
            response.put("success", true);
            response.put("message", "获取位置历史成功");
            response.put("data", locations);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "获取位置历史失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 获取用户最新位置
    @GetMapping("/latest/{userId}")
    public ResponseEntity<Map<String, Object>> getLatestLocation(@PathVariable Long userId) {
        Map<String, Object> response = new HashMap<>();
        try {
            List<Location> locations = locationService.findLatestByUserId(userId);
            if (!locations.isEmpty()) {
                response.put("success", true);
                response.put("message", "获取最新位置成功");
                response.put("data", locations.get(0));
            } else {
                response.put("success", false);
                response.put("message", "未找到位置信息");
            }
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "获取最新位置失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 根据时间范围查询位置
    @GetMapping("/range/{userId}")
    public ResponseEntity<Map<String, Object>> getLocationByTimeRange(
            @PathVariable Long userId,
            @RequestParam String startTime,
            @RequestParam String endTime) {
        Map<String, Object> response = new HashMap<>();
        try {
            Timestamp start = Timestamp.valueOf(startTime);
            Timestamp end = Timestamp.valueOf(endTime);
            List<Location> locations = locationService.findByUserIdAndTimeRange(userId, start, end);
            response.put("success", true);
            response.put("message", "获取指定时间范围位置成功");
            response.put("data", locations);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "获取位置信息失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 计算两点间距离
    @GetMapping("/distance")
    public ResponseEntity<Map<String, Object>> calculateDistance(
            @RequestParam BigDecimal lat1,
            @RequestParam BigDecimal lon1,
            @RequestParam BigDecimal lat2,
            @RequestParam BigDecimal lon2) {
        Map<String, Object> response = new HashMap<>();
        try {
            double distance = locationService.calculateDistance(lat1, lon1, lat2, lon2);
            response.put("success", true);
            response.put("message", "距离计算成功");
            response.put("data", Map.of("distance", distance, "unit", "米"));
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "距离计算失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 删除位置记录
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteLocation(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();
        try {
            locationService.deleteById(id);
            response.put("success", true);
            response.put("message", "位置记录删除成功");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "删除位置记录失败: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}
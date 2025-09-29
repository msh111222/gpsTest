package com.example.gps.service;

import com.example.gps.entity.Location;
import com.example.gps.repository.LocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

@Service
public class LocationService {

    @Autowired
    private LocationRepository locationRepository;

    // 保存位置信息
    public Location saveLocation(Location location) {
        location.setTimestamp(new Timestamp(System.currentTimeMillis()));
        return locationRepository.save(location);
    }

    // 根据ID查询位置
    public Optional<Location> findById(Long id) {
        return locationRepository.findById(id);
    }

    // 查询用户的所有位置记录
    public List<Location> findByUserId(Long userId) {
        return locationRepository.findByUserIdOrderByTimestampDesc(userId);
    }

    // 查询用户最近的位置记录
    public List<Location> findLatestByUserId(Long userId) {
        return locationRepository.findLatestByUserId(userId);
    }

    // 查询指定时间范围内的位置记录
    public List<Location> findByUserIdAndTimeRange(Long userId, Timestamp startTime, Timestamp endTime) {
        return locationRepository.findByUserIdAndTimeRange(userId, startTime, endTime);
    }

    // 删除位置记录
    public void deleteById(Long id) {
        locationRepository.deleteById(id);
    }

    // 计算两点之间的距离（米）
    public double calculateDistance(BigDecimal lat1, BigDecimal lon1, BigDecimal lat2, BigDecimal lon2) {
        final int R = 6371000; // 地球半径（米）

        double lat1Rad = Math.toRadians(lat1.doubleValue());
        double lat2Rad = Math.toRadians(lat2.doubleValue());
        double deltaLat = Math.toRadians(lat2.doubleValue() - lat1.doubleValue());
        double deltaLon = Math.toRadians(lon2.doubleValue() - lon1.doubleValue());

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                        Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }
}
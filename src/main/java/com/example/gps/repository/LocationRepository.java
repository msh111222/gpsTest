package com.example.gps.repository;

import com.example.gps.entity.Location;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LocationRepository extends JpaRepository<Location, Long> {

    // 根据用户ID查询位置记录
    List<Location> findByUserIdOrderByTimestampDesc(Long userId);

    // 查询用户最近的位置记录
    @Query("SELECT l FROM Location l WHERE l.userId = :userId ORDER BY l.timestamp DESC")
    List<Location> findLatestByUserId(@Param("userId") Long userId);

    // 查询指定时间范围内的位置记录
    @Query("SELECT l FROM Location l WHERE l.userId = :userId AND l.timestamp BETWEEN :startTime AND :endTime ORDER BY l.timestamp DESC")
    List<Location> findByUserIdAndTimeRange(@Param("userId") Long userId,
                                            @Param("startTime") java.sql.Timestamp startTime,
                                            @Param("endTime") java.sql.Timestamp endTime);
}
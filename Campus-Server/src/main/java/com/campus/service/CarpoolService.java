package com.campus.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.campus.dto.CarpoolOrderVO;
import com.campus.dto.PassengerVO;
import com.campus.entity.CarpoolOrder;
import com.campus.entity.CarpoolPassenger;
import com.campus.entity.User;
import com.campus.mapper.CarpoolOrderMapper;
import com.campus.mapper.CarpoolPassengerMapper;
import com.campus.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class CarpoolService {

    @Autowired
    private CarpoolOrderMapper carpoolOrderMapper;

    @Autowired
    private CarpoolPassengerMapper carpoolPassengerMapper;

    @Autowired
    private UserMapper userMapper;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public CarpoolOrder publish(Long userId, CarpoolOrder order) {
        order.setUserId(userId);
        order.setCurrentPassengers(0);
        order.setStatus(0);
        carpoolOrderMapper.insert(order);
        return order;
    }

    public List<CarpoolOrderVO> getList(String destination, Integer status, Long userId) {
        LambdaQueryWrapper<CarpoolOrder> wrapper = new LambdaQueryWrapper<>();
        if (destination != null && !destination.isEmpty()) {
            wrapper.eq(CarpoolOrder::getDestination, destination);
        }
        if (status != null) {
            wrapper.eq(CarpoolOrder::getStatus, status);
        } else {
            wrapper.in(CarpoolOrder::getStatus, 0, 1);
        }
        wrapper.orderByDesc(CarpoolOrder::getDepartureTime);
        List<CarpoolOrder> list = carpoolOrderMapper.selectList(wrapper);
        return toVOList(list, userId, false);
    }

    public CarpoolOrderVO getDetail(Long orderId, Long userId) {
        CarpoolOrder order = carpoolOrderMapper.selectById(orderId);
        if (order == null) return null;
        List<CarpoolOrderVO> voList = toVOList(new ArrayList<>() {{ add(order); }}, userId, true);
        return voList.get(0);
    }

    public synchronized boolean join(Long userId, Long orderId) {
        CarpoolOrder order = carpoolOrderMapper.selectById(orderId);
        if (order == null || order.getStatus() == 3 || order.getStatus() == 2) return false;

        LambdaQueryWrapper<CarpoolPassenger> w = new LambdaQueryWrapper<>();
        w.eq(CarpoolPassenger::getOrderId, orderId)
         .eq(CarpoolPassenger::getUserId, userId);
        if (carpoolPassengerMapper.selectCount(w) > 0) return false;

        if (order.getCurrentPassengers() >= order.getMaxPassengers()) {
            order.setStatus(1);
            carpoolOrderMapper.updateById(order);
            return false;
        }

        CarpoolPassenger p = new CarpoolPassenger();
        p.setOrderId(orderId);
        p.setUserId(userId);
        carpoolPassengerMapper.insert(p);

        order.setCurrentPassengers(order.getCurrentPassengers() + 1);
        if (order.getCurrentPassengers() >= order.getMaxPassengers()) {
            order.setStatus(1);
        }
        carpoolOrderMapper.updateById(order);
        return true;
    }

    public boolean cancelJoin(Long userId, Long orderId) {
        LambdaQueryWrapper<CarpoolPassenger> w = new LambdaQueryWrapper<>();
        w.eq(CarpoolPassenger::getOrderId, orderId)
         .eq(CarpoolPassenger::getUserId, userId);
        CarpoolPassenger p = carpoolPassengerMapper.selectOne(w);
        if (p == null) return false;

        carpoolPassengerMapper.deleteById(p.getId());

        CarpoolOrder order = carpoolOrderMapper.selectById(orderId);
        if (order != null) {
            order.setCurrentPassengers(Math.max(0, order.getCurrentPassengers() - 1));
            if (order.getStatus() == 1 && order.getCurrentPassengers() < order.getMaxPassengers()) {
                order.setStatus(0);
            }
            carpoolOrderMapper.updateById(order);
        }
        return true;
    }

    public boolean delete(Long userId, Long orderId) {
        CarpoolOrder order = carpoolOrderMapper.selectById(orderId);
        if (order == null || !order.getUserId().equals(userId)) return false;
        LambdaQueryWrapper<CarpoolPassenger> w = new LambdaQueryWrapper<>();
        w.eq(CarpoolPassenger::getOrderId, orderId);
        carpoolPassengerMapper.delete(w);
        carpoolOrderMapper.deleteById(orderId);
        return true;
    }

    public boolean cancelOrder(Long userId, Long orderId) {
        CarpoolOrder order = carpoolOrderMapper.selectById(orderId);
        if (order == null || !order.getUserId().equals(userId)) return false;
        order.setStatus(3);
        carpoolOrderMapper.updateById(order);
        return true;
    }

    public List<CarpoolOrderVO> getMyOrders(Long userId) {
        LambdaQueryWrapper<CarpoolPassenger> pw = new LambdaQueryWrapper<>();
        pw.eq(CarpoolPassenger::getUserId, userId);
        List<CarpoolPassenger> passengers = carpoolPassengerMapper.selectList(pw);

        Set<Long> orderIds = new HashSet<>();
        for (CarpoolPassenger p : passengers) {
            orderIds.add(p.getOrderId());
        }

        LambdaQueryWrapper<CarpoolOrder> ow = new LambdaQueryWrapper<>();
        ow.eq(CarpoolOrder::getUserId, userId);
        List<CarpoolOrder> myPublished = carpoolOrderMapper.selectList(ow);

        for (CarpoolOrder o : myPublished) {
            orderIds.add(o.getId());
        }

        if (orderIds.isEmpty()) return new ArrayList<>();

        List<CarpoolOrder> orders = carpoolOrderMapper.selectBatchIds(orderIds);
        return toVOList(orders, userId, false);
    }

    private List<CarpoolOrderVO> toVOList(List<CarpoolOrder> list, Long userId, boolean withPassengers) {
        List<CarpoolOrderVO> result = new ArrayList<>();
        if (list.isEmpty()) return result;

        Set<Long> userIds = new HashSet<>();
        Set<Long> orderIds = new HashSet<>();
        for (CarpoolOrder o : list) {
            if (o.getUserId() != null) userIds.add(o.getUserId());
            orderIds.add(o.getId());
        }

        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Map<Long, List<CarpoolPassenger>> passengersByOrder = new HashMap<>();
        if (!orderIds.isEmpty()) {
            LambdaQueryWrapper<CarpoolPassenger> pw = new LambdaQueryWrapper<>();
            pw.in(CarpoolPassenger::getOrderId, orderIds);
            for (CarpoolPassenger p : carpoolPassengerMapper.selectList(pw)) {
                passengersByOrder.computeIfAbsent(p.getOrderId(), k -> new ArrayList<>()).add(p);
                if (p.getUserId() != null) userIds.add(p.getUserId());
            }
        }

        if (!userIds.isEmpty()) {
            for (User u : userMapper.selectBatchIds(userIds)) {
                userMap.put(u.getId(), u);
            }
        }

        Set<Long> joinedOrderIds = new HashSet<>();
        if (userId != null) {
            for (Map.Entry<Long, List<CarpoolPassenger>> e : passengersByOrder.entrySet()) {
                for (CarpoolPassenger p : e.getValue()) {
                    if (userId.equals(p.getUserId())) {
                        joinedOrderIds.add(e.getKey());
                        break;
                    }
                }
            }
        }

        for (CarpoolOrder o : list) {
            CarpoolOrderVO vo = new CarpoolOrderVO();
            vo.setId(o.getId());
            vo.setUserId(o.getUserId());
            User user = o.getUserId() != null ? userMap.get(o.getUserId()) : null;
            vo.setPublisherName(user != null ? user.getName() : "");
            vo.setPublisherAvatar(user != null ? user.getAvatar() : "");
            vo.setDeparture(o.getDeparture());
            vo.setDestination(o.getDestination());
            vo.setDepartureTime(o.getDepartureTime() != null ? o.getDepartureTime().format(FMT) : "");
            vo.setMaxPassengers(o.getMaxPassengers());
            vo.setCurrentPassengers(o.getCurrentPassengers());
            vo.setContactPhone(o.getContactPhone());
            vo.setRemark(o.getRemark());
            vo.setStatus(o.getStatus());
            vo.setJoined(joinedOrderIds.contains(o.getId()));
            vo.setCreateTime(o.getCreateTime() != null ? o.getCreateTime().format(FMT) : "");

            if (withPassengers) {
                List<CarpoolPassenger> pList = passengersByOrder.getOrDefault(o.getId(), new ArrayList<>());
                List<PassengerVO> passengerVOs = new ArrayList<>();
                for (CarpoolPassenger p : pList) {
                    User pu = p.getUserId() != null ? userMap.get(p.getUserId()) : null;
                    PassengerVO pvo = new PassengerVO();
                    pvo.setUserId(p.getUserId());
                    pvo.setNickname(pu != null ? pu.getName() : "");
                    pvo.setAvatar(pu != null ? pu.getAvatar() : "");
                    passengerVOs.add(pvo);
                }
                vo.setPassengers(passengerVOs);
            }

            result.add(vo);
        }
        return result;
    }
}

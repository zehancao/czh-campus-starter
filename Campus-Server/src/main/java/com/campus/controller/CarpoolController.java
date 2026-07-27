package com.campus.controller;

import com.campus.common.Result;
import com.campus.dto.CarpoolOrderVO;
import com.campus.entity.CarpoolOrder;
import com.campus.service.CarpoolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/carpool")
public class CarpoolController {

    @Autowired
    private CarpoolService carpoolService;

    @GetMapping("/list")
    public Result<List<CarpoolOrderVO>> getList(
            @RequestParam(required = false) String destination,
            @RequestParam(required = false) Integer status,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return Result.ok(carpoolService.getList(destination, status, userId));
    }

    @GetMapping("/detail")
    public Result<CarpoolOrderVO> getDetail(@RequestParam Long id,
                                             @RequestAttribute(value = "userId", required = false) Long userId) {
        CarpoolOrderVO vo = carpoolService.getDetail(id, userId);
        if (vo == null) return Result.error(404, "拼车单不存在");
        return Result.ok(vo);
    }

    @PostMapping("/publish")
    public Result<CarpoolOrder> publish(@RequestAttribute("userId") Long userId,
                                         @RequestBody CarpoolOrder order) {
        return Result.ok(carpoolService.publish(userId, order));
    }

    @PostMapping("/join")
    public Result<Boolean> join(@RequestAttribute("userId") Long userId,
                                 @RequestParam Long orderId) {
        boolean ok = carpoolService.join(userId, orderId);
        if (!ok) return Result.error(400, "加入失败（已满/已加入/已取消/已出发）");
        return Result.ok(true);
    }

    @PostMapping("/cancel-join")
    public Result<Boolean> cancelJoin(@RequestAttribute("userId") Long userId,
                                       @RequestParam Long orderId) {
        boolean ok = carpoolService.cancelJoin(userId, orderId);
        if (!ok) return Result.error(400, "退出失败");
        return Result.ok(true);
    }

    @PostMapping("/delete")
    public Result<Boolean> delete(@RequestAttribute("userId") Long userId,
                                   @RequestParam Long orderId) {
        boolean ok = carpoolService.delete(userId, orderId);
        if (!ok) return Result.error(400, "删除失败（非作者或拼车单不存在）");
        return Result.ok(true);
    }

    @PostMapping("/cancel")
    public Result<Boolean> cancelOrder(@RequestAttribute("userId") Long userId,
                                        @RequestParam Long orderId) {
        boolean ok = carpoolService.cancelOrder(userId, orderId);
        if (!ok) return Result.error(400, "取消失败（仅发起人可操作）");
        return Result.ok(true);
    }

    @GetMapping("/my-orders")
    public Result<List<CarpoolOrderVO>> myOrders(@RequestAttribute("userId") Long userId) {
        return Result.ok(carpoolService.getMyOrders(userId));
    }
}

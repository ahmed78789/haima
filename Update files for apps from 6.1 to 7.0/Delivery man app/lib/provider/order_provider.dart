import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/data/model/response/base/api_response.dart';
import 'package:grocery_delivery_boy/data/model/response/order_details_model.dart';
import 'package:grocery_delivery_boy/data/model/response/order_model.dart';
import 'package:grocery_delivery_boy/data/model/response/timeslot_model.dart';
import 'package:grocery_delivery_boy/data/repository/order_repo.dart';
import 'package:grocery_delivery_boy/data/repository/response_model.dart';
import 'package:grocery_delivery_boy/helper/api_checker.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepo? orderRepo;

  OrderProvider({required this.orderRepo});

  // get all current order
  List<OrderModel> _currentOrders = [];
  List<OrderModel> _currentOrdersReverse = [];
  List<TimeSlotModel>? _timeSlots;

  List<OrderModel>? get currentOrders => _currentOrders;
  List<TimeSlotModel>? get timeSlots => _timeSlots;

  Future getAllOrders() async {
    ApiResponse apiResponse = await orderRepo!.getAllOrders();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _currentOrders = [];
      _currentOrdersReverse = [];
      apiResponse.response!.data.forEach((order) {
        OrderModel orderModel = OrderModel.fromJson(order);
        if(orderModel.orderStatus == 'processing' || orderModel.orderStatus == 'out_for_delivery') {
          _currentOrdersReverse.add(orderModel);
        }
      });
      _currentOrders = List.from(_currentOrdersReverse.reversed);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  // get order details
  final OrderDetailsModel _orderDetailsModel = OrderDetailsModel();

  OrderDetailsModel get orderDetailsModel => _orderDetailsModel;
  List<OrderDetailsModel>? _orderDetails;

  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID, BuildContext context) async {
    _orderDetails = null;
    ApiResponse apiResponse = await orderRepo!.getOrderDetails(orderID: orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _orderDetails = [];
      apiResponse.response!.data.forEach((orderDetail) => _orderDetails!.add(OrderDetailsModel.fromJson(orderDetail)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return _orderDetails;
  }

  // get all order history
  List<OrderModel>? _allOrderHistory;
  late List<OrderModel> _allOrderReverse;

  List<OrderModel>? get allOrderHistory => _allOrderHistory;

  Future<List<OrderModel>?> getOrderHistory(BuildContext context) async {
    ApiResponse apiResponse = await orderRepo!.getAllOrderHistory();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _allOrderHistory = [];
      _allOrderReverse = [];
      apiResponse.response!.data.forEach((orderDetail) => _allOrderReverse.add(OrderModel.fromJson(orderDetail)));
      _allOrderHistory = List.from(_allOrderReverse.reversed);
      _allOrderHistory!.removeWhere((order) => (order.orderStatus) != 'delivered');
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return _allOrderHistory;
  }

  // update Order Status
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String? _feedbackMessage;

  String? get feedbackMessage => _feedbackMessage;

  Future<ResponseModel> updateOrderStatus({String? token, int? orderId, String? status}) async {
    _isLoading = true;
    _feedbackMessage = '';
    notifyListeners();
    ApiResponse apiResponse = await orderRepo!.updateOrderStatus(token: token, orderId: orderId, status: status);
    _isLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _feedbackMessage = apiResponse.response!.data['message'];
      responseModel = ResponseModel(apiResponse.response!.data['message'], true);
    } else {
      responseModel = ResponseModel(ApiChecker.getError(apiResponse).errors![0].message, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future updatePaymentStatus({String? token, int? orderId, String? status}) async {
    await orderRepo!.updatePaymentStatus(token: token, orderId: orderId, status: status);
    notifyListeners();
  }

  Future<List<OrderModel>?> refresh(BuildContext context) async{
    getAllOrders();
    Timer(const Duration(seconds: 5), () {});
    return getOrderHistory(context);
  }

  Future<void> initializeTimeSlot() async {
    ApiResponse apiResponse = await orderRepo!.getTimeSlot();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _timeSlots = [];
      apiResponse.response!.data.forEach((timeSlot) => _timeSlots!.add(TimeSlotModel.fromJson(timeSlot)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

}

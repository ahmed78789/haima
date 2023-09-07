import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_delivery_boy/data/model/response/order_model.dart';
import 'package:grocery_delivery_boy/data/model/response/timeslot_model.dart';
import 'package:grocery_delivery_boy/helper/date_converter.dart';
import 'package:grocery_delivery_boy/helper/price_converter.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/provider/auth_provider.dart';
import 'package:grocery_delivery_boy/provider/localization_provider.dart';
import 'package:grocery_delivery_boy/provider/order_provider.dart';
import 'package:grocery_delivery_boy/provider/splash_provider.dart';
import 'package:grocery_delivery_boy/provider/tracker_provider.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/view/base/custom_button.dart';
import 'package:grocery_delivery_boy/view/base/custom_snackbar.dart';
import 'package:grocery_delivery_boy/view/screens/chat/chat_screen.dart';
import 'package:grocery_delivery_boy/view/screens/home/home_screen.dart';
import 'package:grocery_delivery_boy/view/screens/home/widget/order_widget.dart';
import 'package:grocery_delivery_boy/view/screens/order/order_place_screen.dart';
import 'package:grocery_delivery_boy/view/screens/order/widget/custom_divider.dart';
import 'package:grocery_delivery_boy/view/screens/order/widget/delivery_dialog.dart';
import 'package:grocery_delivery_boy/view/screens/order/widget/slider_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? orderModel;
  const OrderDetailsScreen({Key? key, this.orderModel, }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  void _loadData(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.getOrderDetails(widget.orderModel!.id.toString(), context);
    await orderProvider.initializeTimeSlot();

  }
  @override
  void initState() {
    _loadData(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    double? deliveryCharge = 0;
    if(widget.orderModel!.orderType == 'delivery') {
      deliveryCharge = widget.orderModel!.deliveryCharge;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          getTranslated('order_details', context),
          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, order, child) {
          double itemsPrice = 0;
          double discount = 0;
          double tax = 0;
          bool? isVatInclude = false;
          TimeSlotModel? timeSlot;
          if (order.orderDetails != null) {
            for (var orderDetails in order.orderDetails!) {
              itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.quantity!);
              discount = discount + (orderDetails.discountOnProduct! * orderDetails.quantity!);
              tax = tax + (orderDetails.taxAmount! * orderDetails.quantity!);
              isVatInclude = orderDetails.isVatInclude;
            }
            try{
              timeSlot = order.timeSlots!.firstWhere((timeSlot) => timeSlot.id == widget.orderModel!.timeSlotId);
            }catch(e) {
              timeSlot = null;
            }
          }
          double subTotal = itemsPrice + (isVatInclude! ? 0 : tax);
          double totalPrice = subTotal - discount + deliveryCharge! - widget.orderModel!.couponDiscountAmount!;

          return order.orderDetails != null ? Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(getTranslated('order_id', context), style: rubikRegular.copyWith()),
                            Text(' # ${widget.orderModel!.id}', style: rubikMedium.copyWith()),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.watch_later, size: 17),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(DateConverter.isoStringToLocalDateOnly(widget.orderModel!.createdAt!),
                                style: rubikRegular.copyWith()),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    timeSlot != null ? Row(children: [
                      Text('${getTranslated('delivery_time', context)}:', style: rubikRegular),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(DateConverter.convertTimeRange(timeSlot.startTime!, timeSlot.endTime!, context), style: rubikMedium),
                    ]) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeLarge),


                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 5, spreadRadius: 1,
                        )],
                      ),
                      child:  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(getTranslated('customer', context), style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall
                        )),
                        ListTile(
                          leading: ClipOval(
                            child: FadeInImage.assetNetwork(
                              placeholder: Images.placeholderUser,
                              image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.customerImageUrl}/${
                                  widget.orderModel!.customer != null ? widget.orderModel!.customer!.image ?? '' : ''}',
                              height: 40, width: 40, fit: BoxFit.cover,
                              imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholderUser, height: 40, width: 40, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            widget.orderModel!.deliveryAddress == null ? '' :widget.orderModel!.deliveryAddress!.contactPersonName ?? '',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, ),
                          ),
                          trailing: InkWell(
                            onTap: () {
                              if(widget.orderModel!.customer != null) {
                                launchUrlString('tel:${widget.orderModel!.deliveryAddress!.contactPersonNumber}');
                              }else{
                                showCustomSnackBar('user_not_available');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).shadowColor),
                              child: const Icon(Icons.call_outlined, color: Colors.black),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text('${getTranslated('item', context)}:', style: rubikRegular.copyWith()),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(order.orderDetails!.length.toString(), style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                        ]),
                        widget.orderModel!.orderStatus == 'processing' || widget.orderModel!.orderStatus == 'out_for_delivery'
                            ? Row(children: [
                          Text('${getTranslated('payment_status', context)}:',
                              style: rubikRegular.copyWith()),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(getTranslated('${widget.orderModel!.paymentStatus}', context),
                              style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                        ])
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const Divider(height: 20),


                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.orderDetails!.length,
                      itemBuilder: (context, index) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FadeInImage.assetNetwork(
                                placeholder: Images.placeholderImage, height: 70, width: 80, fit: BoxFit.cover,
                                image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.productImageUrl}/${
                                    order.orderDetails![index].productDetails!.image != null
                                        ? order.orderDetails![index].productDetails!.image!.isNotEmpty
                                        ? order.orderDetails![index].productDetails!.image!.first : '' : ''
                                }',
                                imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholderImage, height: 70, width: 80, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.orderDetails![index].productDetails!.name!,
                                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text('${getTranslated('quantity', context)}:', style: rubikRegular),
                                    const SizedBox(
                                      width: 5.0,
                                    ),
                                    Text(order.orderDetails![index].quantity.toString(), style: rubikRegular.copyWith(color: Theme.of(context).primaryColor)),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                Row(children: [
                                  Text(
                                    PriceConverter.convertPrice(context, order.orderDetails![index].price! - order.orderDetails![index].discountOnProduct!.toDouble()),
                                    style: rubikRegular,
                                  ),
                                  const SizedBox(width: 5),

                                  order.orderDetails![index].discountOnProduct! > 0 ? Expanded(child: Text(
                                    PriceConverter.convertPrice(context, order.orderDetails![index].price!.toDouble()),
                                    style: rubikRegular.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  )) : const SizedBox(),
                                ]),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                               Row(children: order.orderDetails![index].variation!.map((variation) =>
                                   Row(children: [

                                    if(variation.type != null)
                                      Container(height: 10, width: 10, decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: Theme.of(context).textTheme.bodyLarge!.color,
                                     )),
                                     const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                     Text(variation.type ?? '',
                                       style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                     ),
                                   ])
                               ).toList(),)



                              ]),
                            ),

                          ]),

                          const Divider(height: 20),
                        ]);
                      },
                    ),


                    (widget.orderModel!.orderNote != null && widget.orderModel!.orderNote!.isNotEmpty) ? Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(width: 1, color: Theme.of(context).hintColor),
                      ),
                      child: Text(widget.orderModel!.orderNote!, style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                    ) : const SizedBox(),

                    // Total
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('items_price', context), style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      Text(PriceConverter.convertPrice(context, itemsPrice), style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    ]),
                    const SizedBox(height: 10),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${getTranslated('tax', context)} ${isVatInclude? getTranslated('include', context) : '' }',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      Text('${isVatInclude? '' : '(+)'} ${PriceConverter.convertPrice(context, tax)}',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                    ]),
                    const SizedBox(height: 10),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: CustomDivider(),
                    ),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('subtotal', context),
                          style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      Text(PriceConverter.convertPrice(context, subTotal),
                          style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                    ]),
                    const SizedBox(height: 10),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('discount', context),
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      Text('(-) ${PriceConverter.convertPrice(context, discount)}',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                    ]),
                    const SizedBox(height: 10),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('coupon_discount', context),
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      Text(
                        '(-) ${PriceConverter.convertPrice(context, widget.orderModel!.couponDiscountAmount)}',
                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('delivery_fee', context),
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      Text('(+) ${PriceConverter.convertPrice(context, deliveryCharge)}',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                    ]),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: CustomDivider(),
                    ),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(getTranslated('total_amount', context),
                          style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor)),
                      Text(
                        PriceConverter.convertPrice(context, totalPrice),
                        style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),
                      ),
                    ]),
                    const SizedBox(height: 30),

                  ],
                ),
              ),
              widget.orderModel!.orderStatus == 'processing' || widget.orderModel!.orderStatus == 'out_for_delivery'
                  ? Padding( padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CustomButton(
                    btnTxt: getTranslated('direction', context),
                    onTap: () {
                      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((position) {
                        MapUtils.openMap(
                            double.parse(widget.orderModel!.deliveryAddress!.latitude!),
                            double.parse(widget.orderModel!.deliveryAddress!.longitude!),
                            position.latitude,
                            position.longitude);
                      });
                    }),
                  )
                  : const SizedBox.shrink(),
              widget.orderModel!.orderStatus != 'delivered' ? Center(
                child: Container(
                  width: 1170,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: CustomButton(btnTxt: getTranslated('chat_with_customer', context), onTap: (){
                    if(widget.orderModel!.customer != null) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(orderModel: widget.orderModel)));
                    }else{
                      showCustomSnackBar('user_not_available');
                    }

                  }),
                ),
              ) : const SizedBox(),

              widget.orderModel!.orderStatus == 'processing' ? Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.05)),
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Transform.rotate(
                  angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SliderButton(
                      action: () {
                        HomeScreen.checkPermission(context, callBack: () {
                          Provider.of<TrackerProvider>(context, listen: false).setOrderID(widget.orderModel!.id!);
                          Provider.of<TrackerProvider>(context, listen: false).startLocationService();
                          String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();
                          Provider.of<OrderProvider>(context, listen: false)
                              .updateOrderStatus(token: token, orderId: widget.orderModel!.id, status: 'out_for_delivery',);
                          Provider.of<OrderProvider>(context, listen: false).getAllOrders();
                          Navigator.pop(context);
                        });
                      },

                      ///Put label over here
                      label: Text(
                        getTranslated('swip_to_deliver_order', context),
                        style: rubikRegular.copyWith(color: Theme.of(context).primaryColor),
                      ),
                      dismissThresholds: 0.5,
                      dismissible: false,
                      icon: const Center(
                          child: Icon(
                            Icons.double_arrow_sharp,
                            color: Colors.white,
                            size: 20.0,
                            semanticLabel: 'Text to announce in accessibility modes',
                          )),

                      ///Change All the color and size from here.
                      radius: 10,
                      boxShadow: const BoxShadow(blurRadius: 0.0),
                      buttonColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).cardColor,
                      baseColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
                  : widget.orderModel!.orderStatus == 'out_for_delivery'
                  ? Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.05)),
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Transform.rotate(
                  angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                  child: Directionality(
                    textDirection: TextDirection.ltr, // set it to rtl
                    child: SliderButton(
                      action: () {
                        String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();

                        if (widget.orderModel!.paymentStatus == 'paid') {
                          Provider.of<TrackerProvider>(context, listen: false).stopLocationService();
                          Provider.of<OrderProvider>(context, listen: false)
                              .updateOrderStatus(token: token, orderId: widget.orderModel!.id, status: 'delivered');
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => OrderPlaceScreen(orderID: widget.orderModel!.id.toString())));
                        } else {
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                  child: DeliveryDialog(
                                    onTap: () {},
                                    totalPrice: totalPrice,
                                    orderModel: widget.orderModel,
                                  ),
                                );
                              });
                        }
                      },

                      ///Put label over here
                      label: Text(
                        getTranslated('swip_to_confirm_order', context),
                        style: rubikRegular.copyWith(color: Theme.of(context).primaryColor),
                      ),
                      dismissThresholds: 0.5,
                      dismissible: false,
                      icon: const Center(
                          child: Icon(
                            Icons.double_arrow_sharp,
                            color: Colors.white,
                            size: 20.0,
                            semanticLabel: 'Text to announce in accessibility modes',
                          )),

                      ///Change All the color and size from here.
                      radius: 10,
                      boxShadow: const BoxShadow(blurRadius: 0.0),
                      buttonColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).cardColor,
                      baseColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ],
          )
              : Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)));
        },
      ),
    );
  }

}

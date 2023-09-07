import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/provider/auth_provider.dart';
import 'package:grocery_delivery_boy/provider/profile_provider.dart';
import 'package:grocery_delivery_boy/provider/splash_provider.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/view/base/status_widget.dart';
import 'package:grocery_delivery_boy/view/screens/auth/login_screen.dart';
import 'package:grocery_delivery_boy/view/screens/html/html_viewer_screen.dart';
import 'package:grocery_delivery_boy/view/screens/profile/widget/profile_button.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  color: Theme.of(context).primaryColor,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        getTranslated('my_profile', context),
                        style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: FadeInImage.assetNetwork(
                              placeholder: Images.placeholderUser,
                              width: 80, height: 80,
                              fit: BoxFit.fill,
                              imageErrorBuilder: (c, o, s) => Image.asset(Images.profilePlaceholder, width: 80, height: 80, fit: BoxFit.cover),

                              image:
                                  '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.deliveryManImageUrl}/${profileProvider.userInfoModel!.image}',
                            )),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        profileProvider.userInfoModel!.fName != null
                            ? '${profileProvider.userInfoModel!.fName ?? ''} ${profileProvider.userInfoModel!.lName ?? ''}'
                            : "",
                        style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraLarge,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                Container(
                  color: Theme.of(context).canvasColor,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslated('theme_style', context),
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                          const StatusWidget()
                        ],
                      ),
                      const SizedBox(height: 20),
                      _userInfoWidget(context: context, text: profileProvider.userInfoModel!.fName),
                      const SizedBox(height: 15),
                      _userInfoWidget(context: context, text: profileProvider.userInfoModel!.lName),
                      const SizedBox(height: 15),
                      _userInfoWidget(context: context, text: profileProvider.userInfoModel!.phone),
                      const SizedBox(height: 20),
                      ProfileButton(icon: Icons.privacy_tip, title: getTranslated('privacy_policy', context), onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HtmlViewerScreen(isPrivacyPolicy: true)));
                      }),
                      const SizedBox(height: 10),
                      ProfileButton(icon: Icons.list, title: getTranslated('terms_and_condition', context), onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HtmlViewerScreen(isPrivacyPolicy: false)));
                      }),
                      const SizedBox(height: 10),
                      ProfileButton(icon: Icons.logout, title: getTranslated('logOut', context), onTap: () {
                        Provider.of<AuthProvider>(context, listen: false).clearSharedData().then((condition) {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                        });
                      }),


                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget _userInfoWidget({String? text, required BuildContext context}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        color: Theme.of(context).canvasColor,
        border: Border.all(color:  Theme.of(context).dividerColor),
      ),
      child: Text(
        text ?? '',
        style: rubikRegular,
      ),
    );
  }
}

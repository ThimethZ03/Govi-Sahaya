// lib/config/routes.dart

import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/menu/language_screen.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/help_screens.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/weather/weather_detail_screen.dart';
import '../screens/ai_crop_doctor/crop_doctor_screen.dart';
import '../screens/ai_crop_doctor/crop_upload_screen.dart';
import '../screens/community_forum/forum_screen.dart';
import '../screens/community_forum/create_post_screen.dart';
import '../screens/community_forum/post_detail_screen.dart';
import '../screens/knowledge_hub/library_screen.dart';
import '../screens/knowledge_hub/guide_detail_screen.dart';
import '../screens/profit_planner/planner_screen.dart';
import '../screens/profit_planner/add_expense_screen.dart';
import '../screens/profit_planner/add_field_screen.dart';
import '../screens/profit_planner/edit_expense_screen.dart';
import '../screens/safety_assist/safety_screen.dart';
import '../screens/safety_assist/first_aid_detail_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/cart_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/news/news_detail_screen.dart' as news_detail;

import '../models/safety_models.dart'; // FirstAidGuide
import '../models/guide_model.dart'; // GuideModel

class AppRoutes {
  // ── Auth ─────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ── Main ─────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String menu = '/menu';

  // ── Account ──────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';

  // ── Menu: Settings & Help ────────────────────────────────────────
  static const String language = '/language';
  static const String settings = '/settings';
  static const String inviteFriends = '/invite-friends';
  static const String rateUs = '/rate-us';
  static const String termsPrivacy = '/terms-privacy';
  static const String reportProblem = '/report-problem';

  // ── Features ─────────────────────────────────────────────────────
  static const String weather = '/weather';
  static const String cropDoctor = '/crop-doctor';
  static const String cropUpload = '/crop-upload';
  static const String forum = '/forum';
  static const String createPost = '/create-post';
  static const String postDetail = '/post-detail';
  static const String library = '/library';
  static const String guideDetail = '/guide-detail';
  static const String profitPlanner = '/profit-planner';
  static const String addExpense = '/add-expense';
  static const String addField = '/add-field';
  static const String editExpense = '/edit-expense';
  static const String safetyAssist = '/safety-assist';
  static const String firstAidDetail = '/first-aid-detail';
  static const String shop = '/shop';
  static const String cart = '/cart';
  static const String productDetail = '/product-detail';
  static const String news = '/news';
  static const String newsDetail = '/news-detail';

  // ── Route Generator ──────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return _createRoute(const LoginScreen());
      case register:
        return _createRoute(const RegisterScreen());
      case home:
        return _createRoute(const HomeScreen());
      case menu:
        return _createRoute(const MenuScreen());

      // ── Account ────────────────────────────────────────────────
      case profile:
        return _createRoute(const ProfileScreen());
      case editProfile:
        return _createRoute(const EditProfileScreen());
      case notifications:
        return _createRoute(const NotificationsScreen());

      // ── Menu: Settings & Help ───────────────────────────────────
      case language:
        return _createRoute(const LanguageScreen());
      case AppRoutes.settings:
        return _createRoute(const SettingsScreen());
      case inviteFriends:
        return _createRoute(const InviteFriendsScreen());
      case rateUs:
        return _createRoute(const RateUsScreen());
      case termsPrivacy:
        return _createRoute(const TermsPrivacyScreen());
      case reportProblem:
        return _createRoute(const ReportProblemScreen());

      // ── Features ───────────────────────────────────────────────
      case weather:
        return _createRoute(const WeatherDetailScreen());
      case cropDoctor:
        return _createRoute(const CropDoctorScreen());
      case cropUpload:
        return _createRoute(const CropUploadScreen());
      case forum:
        return _createRoute(const ForumScreen());
      case createPost:
        return _createRoute(const CreatePostScreen());
      case postDetail:
        final post = settings.arguments;
        return _createRoute(PostDetailScreen(post: post));
      case library:
        return _createRoute(const LibraryScreen());
      case guideDetail:
        final guide = settings.arguments as GuideModel;
        return _createRoute(GuideDetailScreen(guide: guide));
      case profitPlanner:
        return _createRoute(const PlannerScreen());
      case addExpense:
        return _createRoute(const AddExpenseScreen());
      case addField:
        return _createRoute(const AddFieldScreen());
      case editExpense:
        final expense = settings.arguments as Map<String, dynamic>;
        return _createRoute(EditExpenseScreen(expense: expense));

      case safetyAssist:
        return _createRoute(const SafetyScreen());

      case firstAidDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _createRoute(
          FirstAidDetailScreen(
            guide: args['guide'] as FirstAidGuide,
            isDark: args['isDark'] as bool? ?? false,
            lang: args['lang'] as String? ?? 'en',
          ),
        );

      case shop:
        return _createRoute(const ShopScreen());
      case cart:
        return _createRoute(const CartScreen());
      case productDetail:
        final product = settings.arguments;
        return _createRoute(ProductDetailScreen(product: product));
      case news:
        return _createRoute(const NewsScreen());
      case newsDetail:
        final newsId = settings.arguments as String;
        return _createRoute(news_detail.NewsDetailScreen(newsId: newsId));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // ── Slide Transition Helper ─────────────────────────────────────
  static Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

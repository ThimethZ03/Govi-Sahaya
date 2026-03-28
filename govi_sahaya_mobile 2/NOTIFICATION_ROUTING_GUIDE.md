/\*\*

- ============================================================================
- NOTIFICATION ROUTING SYSTEM - IMPLEMENTATION GUIDE
- ============================================================================
-
- This document outlines the unified notification routing solution that handles
- tap-to-redirect from system push notifications, in-app popups, and the
- notification list to the appropriate app screens.
  \*/

// ─── ARCHITECTURE OVERVIEW ────────────────────────────────────────────

/\*\*

- ENTRY POINTS FOR NOTIFICATION TAPS:
-
- 1.  System Push Notification
- └─> NotificationService.\_onNotificationTapped()
-        └─> Uses global navigator key to navigate
-
- 2.  In-App Notification Popup
- └─> NotificationProvider.\_showPopupForLatest()
-        └─> Shows overlay with onTap callback
-
- 3.  Notification List Item
- └─> NotificationsScreen.\_buildNotificationTile()
-        └─> GestureDetector.onTap handler
-
- ALL → NotificationNavigationHandler.navigate()
-       └─> Central routing logic
  \*/

// ─── NOTIFICATION MODEL STRUCTURE ─────────────────────────────────────

/\*\*

- Backend Notification Format:
-
- {
- "\_id": "notification_123",
- "type": "disease_detection", // ← Primary routing key
- "title": "Disease Detected",
- "message": "Leaf spot detected on crops",
- "actionUrl": "/crop-doctor/:id", // ← URL template (optional)
- "data": { // ← Additional routing data
-     "detectionId": "detection_456",
-     "disease": "Leaf Spot",
-     "severity": "high"
- },
- "isRead": false,
- "priority": "high",
- "createdAt": "2024-03-27T10:00:00Z"
- }
-
- REQUIRED FIELDS:
- - type: Notification category (see type mapping below)
- - title, message: Display text
-
- OPTIONAL BUT RECOMMENDED:
- - actionUrl: Navigation template pattern
- - data: Context-specific data for the target screen
- - priority: 'low' | 'normal' | 'high'
    \*/

// ─── NOTIFICATION TYPE MAPPING ────────────────────────────────────────

/\*\*

- Backend Type → Flutter Route Mapping:
-
- ┌──────────────────────┬──────────────────┬─────────────────────┐
- │ Backend Type │ Channel Key │ Target Route │
- ├──────────────────────┼──────────────────┼─────────────────────┤
- │ weather_alert │ weather │ /weather │
- │ price_alert │ price │ /shop │
- │ disease_detection │ crop │ /crop-doctor │
- │ order_update │ order │ /product-detail │
- │ forum_reply │ general │ /post-detail │
- │ general │ general │ /notifications │
- └──────────────────────┴──────────────────┴─────────────────────┘
-
- Function: mapTypeToChannel(String type)
- Location: NotificationNavigationHandler
  \*/

// ─── PAYLOAD FORMAT FOR SYSTEM NOTIFICATIONS ──────────────────────────

/\*\*

- When showing a system push notification via NotificationService.show(),
- the payload should contain serialized notification info:
-
- Expected format (query string):
- "type=disease_detection&id=123&title=Disease&message=Found&actionUrl=/crop-doctor/456&data[detectionId]=456
-
- OR JSON format:
- {"type":"disease_detection","id":"123","title":"Disease","message":"Found","data":{"detectionId":"456"}}
-
- The parsePayload() function handles both formats gracefully.
-
- TIP: When calling showNotification() in NotificationService,
- encode the complete notification info in the payload parameter.
  \*/

// ─── IMPLEMENTATION DETAILS ───────────────────────────────────────────

/\*\*

- 1.  CENTRALIZED ROUTING (NotificationNavigationHandler)
- ─────────────────────────────────────────────────
-
- Key Methods:
-
- - resolveRoute(NotificationModel)
-      → Returns: ({String route, Object? args})
-      → Logic: Switches on type → maps to route + extracts args
-      → Fallback: Uses actionUrl or defaults to /notifications
-
- - navigate(BuildContext, NotificationModel)
-      → Safely executes Navigator.pushNamed()
-      → Handles missing context with try-catch
-      → Fallback: Opens /notifications if navigation fails
-
- - parsePayload(String? payload)
-      → Handles query string AND JSON formats
-      → Returns: Map<String, dynamic>
-
- 2.  GLOBAL NAVIGATOR KEY (main.dart)
- ──────────────────────────────────
-
- - Created: final GlobalKey<NavigatorState> navigatorKey
- - Passed to: MaterialApp(navigatorKey: navigatorKey)
- - Used by: NotificationService.\_onNotificationTapped()
- - Purpose: Enables navigation without BuildContext
-
- 3.  SYSTEM NOTIFICATION TAPS (NotificationService)
- ───────────────────────────────────────────────
-
- Flow:
- a) System notification is tapped
- b) \_onNotificationTapped(NotificationResponse) called
- c) Parse payload → Create NotificationModel
- d) Get context from navigatorKey.currentContext
- e) Call NotificationNavigationHandler.navigate()
-
- 4.  IN-APP POPUP TAPS (NotificationProvider)
- ──────────────────────────────────────────
-
- Flow:
- a) Poll detects new notification
- b) \_showPopupForLatest() creates NotificationModel from data
- c) InAppNotificationService.show() with onTap callback
- d) onTap → NotificationNavigationHandler.navigate()
-
- 5.  NOTIFICATION LIST TAPS (NotificationsScreen)
- ──────────────────────────────────────────────
-
- Flow:
- a) User taps notification tile
- b) GestureDetector.onTap handler
- c) Mark as read (if needed)
- d) NotificationNavigationHandler.navigate()
  \*/

// ─── EXPECTED NAVIGATION BEHAVIOR ──────────────────────────────────────

/\*\*

- weather_alert + actionUrl "/weather"
- └─> Navigate to: /weather
-     Arguments: {weather-specific data}
-
- disease_detection + data.detectionId "det_123"
- └─> Navigate to: /crop-doctor
-     Arguments: {detectionId: "det_123", disease: "...", ...}
-
- order_update + data.orderId "ord_456"
- └─> Navigate to: /product-detail
-     Arguments: {orderId: "ord_456", ...}
-
- forum_reply + data.postId "post_789"
- └─> Navigate to: /post-detail
-     Arguments: {postId: "post_789", commentId: "...", ...}
-
- price_alert (no specific ID)
- └─> Navigate to: /shop
-
- unknown type or missing data
- └─> Navigate to: /notifications (safe fallback)
  \*/

// ─── BACKEND PAYLOAD IMPROVEMENTS (RECOMMENDED) ────────────────────────

/\*\*

- To ensure consistent routing, backend notifications should include:
-
- 1.  TYPE FIELD (REQUIRED)
- - Values: 'weather_alert', 'price_alert', 'disease_detection',
-              'order_update', 'forum_reply', 'general'
- - Used to determine primary route
-
- 2.  ACTION_URL (OPTIONAL)
- - Pattern: '/crop-doctor/:id' or '/orders/:id'
- - Fallback if type is not recognized
-
- 3.  DATA OBJECT (RECOMMENDED)
- - Flat JSON object with context data
- - Examples:
-      - disease_detection: {detectionId, disease, severity}
-      - order_update: {orderId, orderNumber, status}
-      - forum_reply: {postId, commentId, authorName}
-      - weather_alert: {location, weatherType, severity}
-      - price_alert: {cropName, currentPrice, trend}
-
- CURRENT BACKEND SUPPORT:
- ✅ Supported: type, actionUrl, title, message, priority
- ✅ Supported: data field (as Map in model)
- ✅ No changes needed if backend already sends these
  \*/

// ─── ERROR HANDLING & FALLBACKS ────────────────────────────────────────

/\*\*

- Scenario 1: Payload parsing fails
- └─> parsePayload() returns empty Map
-        └─> resolveRoute() returns (route: '/notifications', args: null)
-
- Scenario 2: Type is 'unknown'
- └─> resolveRoute() falls through to default case
-        └─> Checks actionUrl
-        └─> If missing: returns /notifications
-
- Scenario 3: Navigator context missing
- └─> navigate() catches error
-        └─> Prints error message
-        └─> Falls back to /notifications
-
- Scenario 4: Target route doesn't handle arguments
- └─> Navigation still succeeds
-        └─> Route ignores unrecognized arguments
-
- ALL PATHS LEAD TO SAFE OUTCOME
- User always arrives at a valid screen, never a broken state.
  \*/

// ─── TESTING THE IMPLEMENTATION ───────────────────────────────────────

/\*\*

- TEST CASE 1: System Push Notification - Disease Detection
- ──────────────────────────────────────────────────────────
-
- Backend sends:
- {
- "type": "disease_detection",
- "data": {"detectionId": "det_123", "disease": "Powdery Mildew"}
- }
-
- Expected: Tapping notification opens /crop-doctor with detectionId
-
- TEST CASE 2: In-App Popup - Forum Reply
- ────────────────────────────────────────
-
- Backend sends:
- {
- "type": "forum_reply",
- "data": {"postId": "post_789", "commentId": "comment_999"}
- }
-
- Expected: Popup appears, tapping it opens /post-detail with postId
-
- TEST CASE 3: Notification List - Unknown Type
- ──────────────────────────────────────────────
-
- Backend sends:
- {
- "type": "random_type",
- "actionUrl": null
- }
-
- Expected: Tapping notification opens /notifications safely
  \*/

// ─── CONFIGURATION SUMMARY ────────────────────────────────────────────

/\*\*

- FILES MODIFIED:
- ✅ lib/main.dart
- └─ Added: global navigatorKey
- └─ Updated: MaterialApp(navigatorKey: navigatorKey)
-
- ✅ lib/models/notification_model.dart
- └─ Added: data field (Map<String, dynamic>?)
- └─ Updated: fromJson() to parse data
-
- ✅ lib/services/notification_service.dart
- └─ Updated: \_onNotificationTapped() with routing logic
- └─ Added: import NotificationNavigationHandler
-
- ✅ lib/providers/notification_provider.dart
- └─ Updated: \_showPopupForLatest() to use navigation handler
- └─ Added: import NotificationNavigationHandler
-
- ✅ lib/screens/notifications/notifications_screen.dart
- └─ Updated: GestureDetector.onTap to use navigation handler
- └─ Added: import NotificationNavigationHandler
-
- ✅ lib/services/notification_navigation_handler.dart
- └─ NEW: Centralized routing handler class
- └─ Methods: resolveRoute(), mapTypeToChannel(), navigate()
  \*/

// ─── NEXT STEPS ────────────────────────────────────────────────────────

/\*\*

- 1.  TEST the implementation:
- - Send test notifications from backend
- - Tap system push → verify correct route
- - Check in-app popup → verify navigation
- - Test notification list items
-
- 2.  VERIFY backend payloads include:
- - type field (required)
- - data object with context IDs (recommended)
- - actionUrl if type is non-standard
-
- 3.  MONITOR for edge cases:
- - Missing context.mounted checks
- - Payload parsing failures
- - Navigation parameter mismatches
-
- 4.  UPDATE target screens if needed:
- - Ensure each screen handles arguments properly
- - Example: /crop-doctor expects {detectionId}
- - Example: /post-detail expects {postId}
    \*/

// ─── SUPPORT ────────────────────────────────────────────────────────────

/\*\*

- To debug notification routing:
-
- 1.  Check Console Logs:
- - "🔀 Resolving route for type: ..."
- - "📲 Navigating to: ... with args: ..."
- - "❌ Navigation error: ..."
-
- 2.  Verify Payload:
- - Print response.payload in \_onNotificationTapped()
- - Verify type is in the mapping
- - Ensure data has required fields
-
- 3.  Check Navigator State:
- - Verify navigatorKey.currentContext is not null
- - Check if route exists in AppRoutes
- - Ensure target screen handles arguments
    \*/

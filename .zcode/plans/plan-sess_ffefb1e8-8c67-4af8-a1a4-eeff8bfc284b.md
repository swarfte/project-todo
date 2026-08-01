# Project Todo 大型重構計劃

依據你的全部決策（包裝層網路 / VM 用 Riverpod Notifier / freezed 模型 / core/models 集中 / Riverpod provider 取代單例），將項目重組為 feature-first + mvvm + 可維護分層架構。

## 一、目標目錄結構

```
lib/
├── main.dart                       # ProviderScope 包裹 + 初始化
├── app.dart                        # MaterialApp.router(go_router)
├── core/
│   ├── log/logger.dart             # 保留
│   ├── models/                     # 新:freezed 模型(adaptor.dart 取代刪除)
│   │   ├── project.dart            #   @freezed Project
│   │   ├── task.dart               #   @freezed Task
│   │   └── task_step.dart          #   @freezed TaskStep(含 createdAt/created 回退)
│   ├── network/
│   │   ├── api.dart                # 從 lib/api.dart 搬入,只留業務 logic
│   │   ├── handler.dart            # 新:ApiResult + guard()(200/400/401/404/500 分類)
│   │   └── interceptor.dart        # 新:ensureAuth/連線檢查(由 Interceptor.dart 改名)
│   ├── router/
│   │   ├── app_router.dart         # GoRouter 配置(GoRoute + redirect)
│   │   └── routes.dart             # TypedGoRoute(go_router_builder 型別安全導航)
│   ├── state/
│   │   ├── network_providers.dart  # apiServiceProvider / configServiceProvider
│   │   └── app_providers.dart      # authStateProvider / alwaysOnTopProvider
│   └── storage/preferences.dart    # ConfigService 保留
├── common/
│   ├── utils/                      # 新:提取重複邏輯
│   │   ├── date_formatter.dart     # _formatDate(三頁重複)
│   │   ├── step_orderer.dart       # _orderSteps(step page + api 重複)
│   │   └── task_forest.dart        # _buildTaskForest/_groupIntoTrees/_sortTrees
│   └── widgets/                    # 保留:pin_window_button, app_version,
│                                   #   error_message_box, loading_progress_bar,
│                                   #   success_snackbar
└── features/
    ├── projects/
    │   ├── projects_page.dart      # ConsumerWidget
    │   ├── projects_vm.dart        # ProjectsNotifier(AsyncNotifier)
    │   └── widgets/
    │       ├── project_progress_indicator.dart  # 從 project.dart 提取的私有 widget
    │       ├── create_project_dialog.dart
    │       └── edit_project_dialog.dart
    ├── tasks/
    │   ├── tasks_page.dart         # ConsumerWidget
    │   ├── tasks_vm.dart           # TasksNotifier(family: projectId)
    │   └── widgets/
    │       ├── chain_timeline.dart # 從 components/ 搬入
    │       ├── create_task_dialog.dart
    │       └── edit_task_dialog.dart
    └── steps/
        ├── steps_page.dart         # ConsumerWidget
        ├── steps_vm.dart           # StepsNotifier(family: taskId)
        └── widgets/
            ├── create_step_dialog.dart
            └── edit_step_dialog.dart
```

**刪除**: `lib/components/`、`lib/pages/`、`lib/models.dart`、`lib/adaptor.dart`、`lib/api.dart`、空的 `lib/core/router/default.dart`。pubspec 移除未使用的 `get_it`。

## 二、各層設計

### 1. core/models(freezed + json_serializable)
- `Project`、`Task`、`TaskStep` 改為 `@freezed` 不可變類,生成 `fromJson`/`toJson`/`copyWith`。
- 原本 api.dart/各 page 中「重建整個物件改一個欄位」(如 `_toggleComplete`)全部改用 `task.copyWith(isCompleted: !task.isCompleted)`。
- `TaskStep` 的特殊日期回退(`createdAt`→`created`)用自定義 converter 函數搭配 `@JsonKey(fromJson:)` 處理,保留原本防崩潰邏輯。adaptor.dart 因此整個刪除。

### 2. core/network(handler.dart + interceptor.dart + api.dart)
**handler.dart** — 統一結果/錯誤分類(PocketBase SDK 無 dio interceptor,故用包裝層):
```dart
sealed class ApiResult<T> { ... }          // 成功值
class ApiSuccess<T> extends ApiResult<T> { final T data; }
class ApiFailure<T> extends ApiResult<T> { final ApiError error; }
enum ApiError { badRequest, unauthorized, notFound, serverError, network, unknown }

Future<ApiResult<T>> guard<T>(Future<T> Function() action) async {
  try { return ApiSuccess(await action()); }
  on ClientException catch (e) {
    switch (e.statusCode) {                // 400/401/404/500 對應 ApiError
      case 400: return ApiFailure(ApiError.badRequest);
      case 401: return ApiFailure(ApiError.unauthorized);
      case 404: return ApiFailure(ApiError.notFound);
      default: return ApiFailure(e.statusCode>=500 ? serverError : unknown);
    }
  } catch (_) { return ApiFailure(ApiError.network); }
}
```
**interceptor.dart**(由 Interceptor.dart 改名)— 認證/權限:提供 `ensureReady()`(確認 pb 已連線 + authStore.isValid,否則重連/刷新)、監聽 `authStore.onChange`、`isLoggedIn()`。api.dart 每個方法開頭呼叫 `ensureReady()`,讓 api.dart 專注業務。

**api.dart** — 從 `lib/api.dart` 搬入並瘦身:移除每個方法重複的 `if (_pb==null) connectDB()`(交給 interceptor.ensureReady),寫操作回傳 `ApiResult<bool>`,讀操作回傳 `ApiResult<List<...>>`,讓 VM 根據結果切換 UI。保留所有複雜業務(duplicateTask 遞迴、insertStep 鏈結、deleteStep 接合)邏輯不變。

### 3. core/router(go_router + go_router_builder)
- `app_router.dart`:declarative `GoRoute` 三層 `/projects` → `/projects/:projectId`(TasksPage) → `/projects/:projectId/tasks/:taskId`(StepsPage)。`redirect` 做 auth 守衛(未連線→仍進首頁並觸發連線,因本應用無獨立登入頁)。
- `routes.dart`:`@TypedGoRoute` 配合 go_router_builder 生成型別安全導航 helper(如 `ProjectsRoute()`、`TasksRoute(projectId: x)`)。
- 導航改傳 **id**(不傳整個物件);目標頁用 id 從對應 Riverpod provider 查找 metadata(AppBar 標題等)。比 Navigator.push 傳 widget 更可恢復、支援深連結。

### 4. core/state + features/*_vm.dart(Riverpod 3.x)
- `network_providers.dart`:`apiServiceProvider`(Provider,建構單一 APIService)、`configServiceProvider`。VM 透過 `ref.read(apiServiceProvider)` 存取,測試可 override。
- `app_providers.dart`:`authStateProvider`(StreamProvider 監聽 authStore)、`alwaysOnTopProvider`(NotifierProvider,取代 pin_window_button 的全域 ValueNotifier)。
- 每個 `*_vm.dart` 為 `AsyncNotifier`,管理 loading/error/data + CRUD:
  - `projects_vm.dart`:`ProjectsNotifier` 載入專案列表+統計、create/update/delete。
  - `tasks_vm.dart`:`tasksNotifierProvider(family: projectId)`,管理任務樹+步驟統計。
  - `steps_vm.dart`:`stepsNotifierProvider(family: taskId)`,管理步驟鏈。
- 各 `*_page.dart` 改 `ConsumerWidget`/`ConsumerStatefulWidget`,用 `ref.watch` 訂閱 AsyncValue,dialog 仍用 showDialog 但呼叫 VM 方法。

### 5. common/utils(提取重複邏輯)
`date_formatter.dart`(三頁重複的 `_formatDate`)、`step_orderer.dart`(step page + api 重複的 `_orderSteps`)、`task_forest.dart`(task page 的 `_buildTaskForest`/`_groupIntoTrees`/`_sortTrees` + `FlatTaskNode`)。原 `chain_timeline.dart` 的 `FlatTaskNode` 移入 `task_forest.dart`。

## 三、執行階段(每階段結束確認可編譯/分析通過)

1. **模型層**:建 core/models 三個 freezed 模型 → 跑 build_runner 生成 → 刪 adaptor.dart/models.dart。
2. **網路層**:寫 handler.dart、interceptor.dart(改名)→ api.dart 搬入並接上 guard/ensureReady、改回傳 ApiResult。
3. **state 層**:core/state 的 providers + 三個 *_vm.dart(AsyncNotifier)。
4. **utils + widgets 搬遷**:提取重複邏輯到 utils,搬 components→features/*/widgets。
5. **router**:app_router.dart + routes.dart,改 app.dart 為 MaterialApp.router,main.dart 加 ProviderScope。
6. **pages 重寫**:三個 page 改 ConsumerWidget + VM 訂閱 + id 導航。
7. **清理**:刪 components/、pages/、舊檔,移除 get_it。
8. **生成 + 驗證**:`dart run build_runner build --delete-conflicting-outputs` → `flutter analyze` 修正所有錯誤 → `flutter test`(如有)。

## 四、風險與對應
- **免費生成檔案衝突**:全程最後一次性 build_runner,以 `--delete-conflicting-outputs` 處理。
- **api.dart 回傳型別從 bool 改 ApiResult 會牽動所有呼叫者**:在 VM 層一次性吸收(VM 把 ApiResult 轉成給 UI 的訊息)。
- **Riverpod 3.x Notifier 在 build 時整體重建**:確保 Notifier 狀態以不可變 freezed 物件承載,避免重建遺失。
- **保留所有現有業務註解與防呆邏輯**(鏈結 splice、cycle guard、fold 透傳等)原樣搬移,不改行為。

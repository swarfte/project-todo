import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter Gradle Plugin 必須放在 Android 和 Kotlin plugin 之後。
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * 載入 android/key.properties。
 *
 * rootProject 指向 android/ 目錄，因此：
 * rootProject.file("key.properties")
 * 對應 android/key.properties。
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}

android {
    namespace = "com.example.project_todo"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        /*
         * 不要改變 applicationId。
         * Android 使用它識別是否為同一個 App。
         */
        applicationId = "com.example.project_todo"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            /*
             * 防止 release build 在 key.properties 不存在時，
             * 意外改用 debug key 或產生未正確簽署的 APK。
             */
            check(keystorePropertiesFile.exists()) {
                "找不到 android/key.properties，無法建立已簽署的 release APK。"
            }

            val releaseStoreFile =
                keystoreProperties.getProperty("storeFile")
                    ?: error("key.properties 缺少 storeFile")

            val releaseStorePassword =
                keystoreProperties.getProperty("storePassword")
                    ?: error("key.properties 缺少 storePassword")

            val releaseKeyAlias =
                keystoreProperties.getProperty("keyAlias")
                    ?: error("key.properties 缺少 keyAlias")

            val releaseKeyPassword =
                keystoreProperties.getProperty("keyPassword")
                    ?: error("key.properties 缺少 keyPassword")

            /*
             * storeFile=android-release.jks
             * 對應 android/android-release.jks。
             */
            storeFile = rootProject.file(releaseStoreFile)
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword

            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        debug {
            /*
             * Debug build 繼續使用 Android 預設的 debug key。
             * 正式發布時不要使用 app-debug.apk。
             */
        }

        release {
            /*
             * 這是最關鍵的修改：
             * release build 使用固定的 android-release.jks。
             */
            signingConfig = signingConfigs.getByName("release")

            /*
             * 暫時關閉程式碼縮減，方便先測試安裝及更新。
             * 簽署測試成功後，可以視需要再啟用。
             */
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // ✅ Must match google-services.json -> client -> android_client_info -> package_name
    namespace = "com.govisahaya.mobile"

    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        // ✅ Must match google-services.json package_name
        applicationId = "com.govisahaya.mobile"

        // If flutter.minSdkVersion gives issues, set a fixed value like 21
        minSdk = flutter.minSdkVersion
        // minSdk = 21

        targetSdk = 36

        versionCode = 1
        versionName = "1.0.0"

        multiDexEnabled = true
    }

    compileOptions {
        // ✅ Keep 17 if you want (fine)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // ✅ REQUIRED for flutter_local_notifications (and some libs)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // ✅ For testing only. For production add a proper keystore.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Desugaring library (REQUIRED)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Firebase BOM (keeps versions consistent)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    implementation("androidx.multidex:multidex:2.0.1")
}
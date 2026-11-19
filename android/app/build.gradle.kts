import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

// Store builds are explicit; the existing phone preview keeps its identity.
val chessStoreBuild = providers.gradleProperty("chessStoreBuild")
    .orElse("false").get().toBooleanStrict()
require(chessStoreBuild || gradle.startParameter.taskNames.none { it.endsWith("bundleRelease", ignoreCase = true) }) {
    "Release App Bundles require explicit chessStoreBuild=true. Debug-signed preview bundles are forbidden."
}
val chessStoreApplicationId = providers.gradleProperty("chessStoreApplicationId")
    .orElse("com.zpgames.satrancplatformu").get().trim()
val chessUploadProperties = Properties()
if (file("google-services.json").isFile) {
    apply(plugin = "com.google.gms.google-services")
}
if (chessStoreBuild) {
    val firebaseConfigFile = file("google-services.json")
    require(firebaseConfigFile.isFile) { "The registered Firebase Android configuration is required for Play builds." }
    val firebaseConfig = firebaseConfigFile.readText()
    val firebasePackagePattern = Regex("\"package_name\"\\s*:\\s*\"${Regex.escape(chessStoreApplicationId)}\"")
    require(firebasePackagePattern.containsMatchIn(firebaseConfig)) {
        "Firebase configuration must match the permanent Play application ID."
    }
    // Google Services applied above
    require(chessStoreApplicationId.matches(Regex("[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*){2,}"))) {
        "A valid permanent store application ID is required."
    }
    require(!chessStoreApplicationId.startsWith("com.example.")) {
        "The temporary preview application ID cannot be used for Play builds."
    }
    val propertiesFile = rootProject.file("key.properties")
    require(propertiesFile.isFile) {
        "Play upload signing is missing. Prepare android/key.properties before a store build."
    }
    propertiesFile.inputStream().use { chessUploadProperties.load(it) }
    for (property in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        require(!chessUploadProperties.getProperty(property).isNullOrBlank()) {
            "Play upload signing is incomplete: missing $property."
        }
    }
    require(rootProject.file(chessUploadProperties.getProperty("storeFile")).isFile) {
        "The configured Play upload keystore does not exist."
    }
}

android {
    namespace = "com.example.chess_platform"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = chessStoreApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (chessStoreBuild) {
            create("playUpload") {
                storeFile = rootProject.file(chessUploadProperties.getProperty("storeFile"))
                storePassword = chessUploadProperties.getProperty("storePassword")
                keyAlias = chessUploadProperties.getProperty("keyAlias")
                keyPassword = chessUploadProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (chessStoreBuild) "playUpload" else "debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
